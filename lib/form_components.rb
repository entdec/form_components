# frozen_string_literal: true

require "view_component"
require "slim-rails"
require "importmap-rails"
require "form_components/version"
require "form_components/engine"

# A form builder whose fields are view components, each in
# app/components/form_components/<name>/ with its template and, for some, a
# Stimulus controller and styles. See the README.
module FormComponents
end
