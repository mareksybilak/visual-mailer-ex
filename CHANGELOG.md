# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-01-19

### Added

- Initial release
- MJML rendering via Rust NIF (`mjml` hex package)
- JSON to MJML converter
- Variable interpolation with `{{variable}}` and `{{variable|default:value}}` syntax
- HTML to plain text converter
- Template validation
- Ecto schemas for templates and campaigns
- Phoenix LiveView component for editor integration
- Mix task installer (`mix visual_mailer.install`)
- Swoosh integration for email sending
