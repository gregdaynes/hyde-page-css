require 'jekyll'
require_relative 'generated_page_css_file.rb'

module Jekyll
  class Renderer
    def render_layout(output, layout, info)
      Hyde::Page::Css.new(layout, info).generate

      # TODO Would be nice to call super here instead of cloned logic from Jekyll internals
      payload["content"] = output
      payload["layout"]  = Utils.deep_merge_hashes(layout.data, payload["layout"] || {})

      render_liquid(
        layout.content,
        payload,
        info,
        layout.path
      )
    end
  end
end

module Hyde
  module Page
    class Css
      @@config = {
        "asset_path" => 'assets/css',
        "file_output_path" => 'assets/css',
        "css_minify" => true,
        "enable" => true,
        "keep_files" => true
      }

      def initialize(layout, info)
        @site = info[:registers][:site]
        @page = info[:registers][:page]
        @data = layout.data
        @config = @@config.merge(@site.config.dig('hyde_page_css'))

        @qualified_asset_path = File.join(*[@site.source, @config['asset_path']].compact)

        if config('keep_files') == true
          @site.config['keep_files'].push(config('file_output_path'))
        end

        if @page["css"].nil?
          @page["css"] = []
        else
          @page["css"] = [@page["css"]]
        end
      end

      def generate
        return unless config('enable') == true
        @page["css"].unshift(@data['css'])

        file_groups = flatten_group(@page["css"])

        css_files = []

        for files in file_groups do
          break if !files&.length

          data = concatenate_files(files.compact)

          next if data == ""

          data = minify(data)
          file = generate_file(data)
          css_files << file.url

          # file already exists, so skip writing out the data to disk
          next if @site.static_files.find { |x| x.name == file.name }

          # place file data into the new file
          file.file_contents = data

          # assign static file to list for jekyll to render
          @site.static_files << file
        end

        # the recursive nature of this will sometimes have duplicate css files
        @page['css_files'] = css_files.uniq
      end

    private

      def config(*keys)
        @config.dig(*keys)
      end

      def flatten_group(arr, acc = [])
        return [arr] if !arr.last.is_a?(Array)

        acc += [arr.first]
        acc += flatten_group(arr.last)
      end

      def concatenate_files(files, data = '')
        for file in files do
          # tmp page required to handle anything with frontmatter/yaml header
          tmp_page = Jekyll::PageWithoutAFile.new(@site, nil, config('asset_path'), file)
          path = File.join([@qualified_asset_path, file])

          begin
            file_contents = File.read(path)
            tmp_page.content = file_contents
            data << Jekyll::Renderer.new(@site, tmp_page).run()
          rescue
            Jekyll.logger.warn('Page CSS Warning:', "Unable to find #{path}")
          end
        end

        data
      end

      def minify(data)
        return data if config('minify') == false

        converter_config = { 'sass' => { 'style' => 'compressed' } }
        Jekyll::Converters::Scss.new(converter_config).convert(data)
      end

      def generate_file(data)
        hashed_file_name = Digest::MD5.hexdigest(data) + '.css'
        Hyde::Page::GeneratedPageCssFile.new(@site, config('asset_path'), hashed_file_name)
      end
    end
  end
end
