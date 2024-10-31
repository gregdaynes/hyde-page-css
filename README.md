Hyde Page CSS
=============

A Jekyll 4 plugin that enables concatenating, processing and caching css files for pages.


Installation
------------

1. Add Hyde Page CSS to your Gemfile

`gem 'hyde-page-css', '~> 0.6.0'`

2. Add entry to your Jekyll config under plugins

```yaml
plugins:
  - hyde-page-css
  ...
```

3. Add the liquid tag to your layout

```liquid
{%- for file in page.css_files -%}
<link rel="stylesheet" href="{{ file.path | prepend: '/' | prepend: site.baseurl }}">
{%- endfor %}
```
which will render as the following, based on the number of separate css files.

```html
<link rel="stylesheet" href="/assets/css/7ccd0b378a0983457a529eb1bbb165a5.css">
```

Alternatively load the CSS inline

```liquid
{%- for file in page.css_files -%}
<style>
  {{ file.content }}
</style>
{%- endfor %}
```

```html
<style>
  body {
    padding: 0;
  }
</style>
```

A third option to automatically switch between links and inline css

```liquid
{%- for style in page.automatic_styles -%}
    {{ style }}
{%- endfor -%}
```

Each separate stylesheet is checked against the threshold, and if met, it will be inlined in the page. In dev_mode or with livereload enabled, the threshold is ignored and the css is always linked.

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
  source: assets/css
  destination: assets/css
  minify: true
  enable: true
  keep_files: true
  livereload: false
  automatic_inline_threshold: 4096
```

`source`
: relative path from the root of your Jekyll directory to the source css file directory

`destination`
: relative path from the root of your generated site to the location of the generated css files

`minify`
: minify the css generated (reuses Jekyll's SASS compiler, so you can also use SASS/SCSS in your files)

`enable`
: will generate the css files when enabled, otherwise will skip the process at build time

`keep_files`
: will not delete files between builds, and will reuse existing files if they match.

`livereload`
: will not include the cache-busting hash in the filename, useful for development with livereload.
: only applies to `page.automatic_style`
: will always use separate files for each css file included, useful for development with livereload.

`automatic_inline_threshold`
: only applies to `page.automatic_style`
: if the css file is smaller than this threshold, it will be inlined in the page instead of linked.
