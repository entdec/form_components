# frozen_string_literal: true

# A Rails app to try the components in (bin/rails server, from test/dummy)
# and to test them with (test/test_helper.rb)
require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "turbo-rails"
require "hotwire_combobox"
require "form_components"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = "dummy"
    config.hosts.clear
    config.logger = Logger.new(nil) if Rails.env.test?
    config.action_dispatch.show_exceptions = :rescuable if Rails.env.test?
    config.action_controller.allow_forgery_protection = false if Rails.env.test?
  end
end
