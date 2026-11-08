# frozen_string_literal: true

module FormComponents
  module Dsl
    extend ActiveSupport::Concern

    included do
      private

      def render_component(component_name, *, &)
        component = "FormComponents::#{component_name.to_s.camelcase}::Component".safe_constantize&.new(self, *)
        component&.render_in(@template, &)
      end
    end

    class_methods do
      # Defines a text-field-like form component for the given kind
      # @param kind [Symbol] the kind of text-field-like form component
      def text_field_form_component(kind = :text)
        define_method("#{kind}_field") do |method, options = {}|
          # The tr is to deal with datetime-local
          render_component(:text_field, @object, method, options.merge(type: kind.to_s.tr("_", "-").to_sym))
        end
      end

      # Defines a form component method with the given name
      # @param name [Symbol] the name of form component
      def form_component(name)
        alias_method :"_original_#{name}", name
        define_method(name) do |method, *args, &block|
          render_component(name, @object, method, *args, &block)
        end
      end
    end
  end
end
