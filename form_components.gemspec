# frozen_string_literal: true

require_relative "lib/form_components/version"

Gem::Specification.new do |spec|
  spec.name = "form_components"
  spec.version = FormComponents::VERSION
  spec.authors = ["Tom de Grunt"]
  spec.email = ["tom@degrunt.nl"]
  spec.homepage = "https://github.com/entdec/form_components"
  spec.summary = "A form builder for Rails that renders its fields as Tailwind view components"
  spec.description = "Text fields, text areas, check boxes, radio buttons, selects, a combobox, ratings, scales, color and file fields, a submit button and nested forms as view components, with their Stimulus controllers and styles, in a Rails engine."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["{app,config,lib,vendor}/**/*", "MIT-LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "view_component", ">= 3"
  spec.add_dependency "slim-rails", ">= 3"
  spec.add_dependency "importmap-rails", ">= 2"
end
