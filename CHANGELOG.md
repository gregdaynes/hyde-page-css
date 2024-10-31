# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Refactored

- Use Jekyll::Cache instead of poro cache.

## [0.6.0] - 2024-10-30

### Added

- Livereload config to disable cache-busting hash on filenames.
- automatic_inline_threshold to control when to inline css.
- automatic_styles to automatically switch between links and inline css.

### Fixed

- Allow incremental builds to write updates.

## [0.5.1] - 2024-10-25

### Fixed

- CSS declarations can be empy in the frontmatter.
