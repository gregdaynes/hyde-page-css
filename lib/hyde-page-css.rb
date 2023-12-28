require "jekyll"
require "digest"

Jekyll::Hooks.register :pages, :post_init do |page|
  Hyde::Page::Css.new(page).run if page.instance_of? Jekyll::Page
end

Jekyll::Hooks.register :documents, :pre_render do |document|
  Hyde::Page::Css.new(document).run if document.instance_of? Jekyll::Document
end

module Hyde
  module Page
    class Css
      VERSION = "0.4.3"
    end

    class GeneratedCssFile < Jekyll::StaticFile
      attr_accessor :file_contents
      attr_reader :generator

      def initialize(site, dir, name)
        @site = site
        @dir = dir
        @name = name
        @relative_path = File.join(*[@dir, @name].compact)
        @extname = File.extname(@name)
        @type = @collection&.label&.to_sym
        @generator = "hyde-page-css"
      end

      def write(dest)
        dest_path = destination(dest)
        return false if File.exist?(dest_path)

        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.rm(dest_path) if File.exist?(dest_path)

        File.open(dest_path, "w") do |output_file|
          output_file << file_contents
        end

        true
      end
    end

    class Css
      @@config = {
        "source" => "assets/css",
        "destination" => "assets/css",
        "minify" => true,
        "enable" => true,
        "keep_files" => true,
        "dev_mode" => false
      }

      def initialize(page)
        @page = page
        @site = page.site
        @config = fetch_config
        @site.data["_hyde_pages_cache"] ||= {}

        if keep_files? && !dev_mode?
          @site.config.fetch("keep_files").push(destination)
        end
      end

      def run
        css = fetch_css(@page)
        layout = fetch_layout(fetch_layout_name(@page))
        css_groups = parent_layout_css(layout, css).reverse
        return if css_groups.flatten.empty?

        for group in css_groups
          lookup_name = names_to_key(group)
          cache_entry = @site.data["_hyde_pages_cache"].fetch(lookup_name, nil)

          if cache_entry.nil?
            data = concatenate_files(group)
            break if data == ""

            data = minify(data)
            break if data == ""

            generated_file = generate_file(group, data)

            # place file data into the new file
            generated_file.file_contents = data

            if @site.static_files.find { |static_file| static_file.name == generated_file.name }.nil?
              # assign static file to list for jekyll to render
              @site.static_files << generated_file
            end

            # add to cache
            cache_entry = {
              url: generated_file.url,
              data: data
            }
            @site.data["_hyde_pages_cache"][lookup_name] = cache_entry
          end

          # assign to page.data.css_files for liquid output
          add_to_urls(cache_entry&.fetch(:url, nil))
        end
      end

      private

      def names_to_key(names)
        names.join("-")
      end

      def add_to_urls(url)
        @page.data["css_files"] ||= []
        @page.data["css_files"].push(url)
      end

      def fetch_config
        @@config.merge(@site.config.fetch("hyde_page_css", {}))
      end

      def keep_files?
        @config.fetch("keep_files") == true
      end

      def dev_mode?
        @config.fetch("dev_mode") == true
      end

      def minify?
        @config.fetch("minify") == true
      end

      def destination
        @config.fetch("destination")
      end

      def source
        @config.fetch("source")
      end

      def qualified_source
        File.join(*[@site.source, source].compact)
      end

      def fetch_layout_name(obj_with_data, default = nil)
        obj_with_data.data.fetch("layout", default)
      end

      def fetch_css(obj_with_data, default = [])
        [obj_with_data.data.fetch("css", [])]
      end

      def fetch_layout(layout_name, default = nil)
        @site.layouts.fetch(layout_name, default)
      end

      def parent_layout_css(layout, css)
        if layout.nil?
          return css
        end

        layout_name = fetch_layout_name(layout)
        parent_layout = fetch_layout(layout_name)
        css = css.concat(fetch_css(layout))

        parent_layout_css(parent_layout, css)
      end

      def concatenate_files(files, data = [])
        files.each do |file_name|
          # tmp page required to handle anything with frontmatter/yaml header
          tmp_page = Jekyll::PageWithoutAFile.new(@site, nil, source, file_name)
          path = File.join([qualified_source, file_name])

          begin
            tmp_page.content = File.read(path)
            data.push(Jekyll::Renderer.new(@site, tmp_page).run)
          rescue
            Jekyll.logger.warn("Page CSS Warning:", "Unable to find #{path}")
          end
        end

        data.join("\n")
      end

      def style
        if dev_mode?
          "expanded"
        elsif !minify?
          "expanded"
        else
          "compressed"
        end
      end

      def minify(data)
        return data unless minify?

        converter_config = {"sass" => {"style" => style}}
        Jekyll::Converters::Scss.new(converter_config).convert(data)
      end

      def generate_file(files, data)
        file_name = generate_file_name(files, data)
        Hyde::Page::GeneratedCssFile.new(@site, source, file_name)
      end

      def generate_file_name(files, data, prefix: nil)
        file_names = [prefix]

        if dev_mode?
          files.each { |file| file_names.push(file.gsub(".css", "")) }
        end

        file_names.push(Digest::MD5.hexdigest(data)[0, 6])

        file_names.compact.join("-") + ".css"
      end
    end
  end
end
