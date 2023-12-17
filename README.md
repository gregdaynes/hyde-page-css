Hyde Page CSS
=============

A Jekyll 4 plugin that enables concatenating, processing and caching css files for pages.


Installation
------------

1. Add Hyde Page CSS to your Gemfile

`gem 'hyde-page-css', '~> 0.2.3'`

2. Add entry to your Jekyll config under plugins

```yaml
plugins:
  - hyde_page_css
  ...
```

3. Add the liquid tag to your layout

```liquid
{%- for file in page.css_files -%}
<link rel="stylesheet" href="{{ file | prepend: '/' | prepend: site.baseurl }}">
{%- endfor %}
```

which will render as the following, based on the number of separate css files.

```html
<link rel="stylesheet" href="/assets/css/7ccd0b378a0983457a529eb1bbb165a5.css">
```

4. Add `css:` to your frontmatter.

`css:` is a list of files defined in the `asset_path` in configuration.

```html
---
layout: home.html
	- home.css
	- promotion.css
---
<h1>Hyde Page CSS</h1>

<div class="promotion">Try now!</div>
```

The generated css file will contain the contents of `home.css` and `promotion.css` then cached.

If any other page uses `home.css` and `promotion.css` they will reuse the same generated css file.

Configuration
-------------

Hyde Page CSS comes with the following configuration. Override as necessary in your Jekyll Config

```yaml
hyde_page_css:
  asset_path: assets/css
  file_output_path: assets/css
  css_minify: true
  enable: true
  keep_files: true
	dev_mode: false
```

`asset_path`
: relative path from the root of your Jekyll directory to the source css file directory

`file_output_path`
: relative path from the root of your generated site to the location of the generated css files

`css_minify`
: minify the css generated (reuses Jekyll's SASS compiler, so you can also use SASS/SCSS in your files)

`enable`
: will generate the css files when enabled, otherwise will skip the process at build time

`keep_files`
: will not delete files between builds, and will reuse existing files if they match.

`dev_mode`
: skip minification of css, the filename will be formed of the files included with a trailing hash to bust cache. eg: `base.css, home.css => base-home-2d738a.css`.

