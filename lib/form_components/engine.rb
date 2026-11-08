# frozen_string_literal: true

module FormComponents
  class Engine < ::Rails::Engine
    engine_name "form_components"

    initializer "form_components.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        # The components' Stimulus controllers
        app.config.assets.paths << root.join("app/components")
        # JS Color Picker, for the color field
        app.config.assets.paths << root.join("vendor/javascript")
      end
    end

    initializer "form_components.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
      app.config.importmap.cache_sweepers << root.join("app/components")
    end
  end
end
