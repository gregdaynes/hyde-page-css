require File.expand_path('../lib/hyde_page_css.rb', __FILE__)

Gem::Specification.new do |s|
  s.name = "hyde-page-css"
  s.version = Hyde::Page::Css::VERSION
  s.summary = "Plugin for jekyll to enable per page css files"
  s.description = "Hyde Page CSS is a plugin for Jekyll that enables concatenating, processing and caching css files for separate pages."
  s.authors = ["Gregory Daynes"]
  s.email   = "email@gregdaynes.com"
  s.homepage = "https://github.com/gregdaynes/hyde-page-css"
  s.license = "MIT"

  s.files = Dir["{lib}/**/*.rb"]
  s.require_path = 'lib'

  s.add_development_dependency "jekyll", ">= 4.0", "< 5.0"
end
