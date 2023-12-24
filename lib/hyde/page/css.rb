require 'jekyll'
require_relative "generated_page_css_file"

module Hyde
  module Page
    class Css
      @@config = {
        "asset_path" => "assets/css",
        "file_output_path" => "assets/css",
        "css_minify" => true,
        "enable" => true,
        "keep_files" => true,
        "dev_mode" => false
      }

      def initialize(layout, info)
        @site = info[:registers][:site]
        @page = info[:registers][:page]
        @data = layout.data
        @config = @@config.merge(@site.config.dig("hyde_page_css") || {})

        @qualified_asset_path = File.join(*[@site.source, @config["asset_path"]].compact)

        if config("keep_files") == true && config("dev_mode") == false
          @site.config["keep_files"].push(config("file_output_path"))
        end

        @page["css"] = if @page["css"].nil?
          []
        else
          [@page["css"]]
        end
      end

      def generate
        return unless config("enable") == true
        @page["css"].unshift(@data["css"])

        file_groups = flatten_group(@page["css"])

        css_files = []

        for files in file_groups do
          break if !files&.length

          data = concatenate_files(files.compact)
          data = minify(data)
          next if data == ""

          file = generate_file(files, data)
          css_files << file.url

          # file already exists, so skip writing out the data to disk
          next if @site.static_files.find { |x| x.name == file.name }

          # place file data into the new file
          file.file_contents = data

          # assign static file to list for jekyll to render
          @site.static_files << file
        end

        # the recursive nature of this will sometimes have duplicate css files
        @page["css_files"] = css_files.uniq
      end

      private

      def config(*)
        @config.dig(*)
      end

      def flatten_group(arr, acc = [])
        return [arr] if !arr.last.is_a?(Array)

        acc += [arr.first]
        acc += flatten_group(arr.last)
      end

      def concatenate_files(files, data = "")
        for file in files do
          # tmp page required to handle anything with frontmatter/yaml header
          tmp_page = Jekyll::PageWithoutAFile.new(@site, nil, config("asset_path"), file)
          path = File.join([@qualified_asset_path, file])

          begin
            file_contents = File.read(path)
            tmp_page.content = file_contents
            # original jekyll renderer, not our modified version
            data << Jekyll::Renderer.new(@site, tmp_page).run
          rescue
            Jekyll.logger.warn("Page CSS Warning:", "Unable to find #{path}")
          end
        end

        data
      end

      def minify(data)
        style = if config("dev_mode") == true
          "expanded"
        elsif config("css_minify") == false
          "expanded"
        else
          "compressed"
        end

        converter_config = {"sass" => {"style" => style}}
        Jekyll::Converters::Scss.new(converter_config).convert(data)
      end

      def generate_file(files, data)
        file_name = generate_file_name(files, data)

        Hyde::Page::GeneratedPageCssFile.new(@site, config("asset_path"), file_name)
      end

      def generate_file_name(files, data, prefix: nil)
        file_names = [prefix]

        if config("dev_mode")
          files.each { |file| file_names.push(file.gsub(".css", "")) }
        end

        file_names.push(Digest::MD5.hexdigest(data)[0, 6])

        file_names.compact.join("-") + ".css"
      end
    end
  end
end
