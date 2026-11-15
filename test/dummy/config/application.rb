# frozen_string_literal: true

# A Rails app to try the components in (bin/rails server, from test/dummy)
# and to test them with (test/test_helper.rb)
require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_text/engine"
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
    # For the rich text area's uploads and Action Text, in tmp/ (see config/database.yml, config/storage.yml)
    config.active_storage.service = :local

    # The tables of Active Storage, Action Text and Article
    config.after_initialize do
      ActiveRecord::Migration.verbose = false
      ActiveRecord::MigrationContext.new(
        [ActiveStorage::Engine, ActionText::Engine].map { |engine| engine.root.join("db/migrate") } << root.join("db/migrate")
      ).migrate
    end
  end
end
