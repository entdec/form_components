module FormComponents
  module Submit
    class Component < FormComponents::Base::Component
      attr_reader :value
      def initialize(form, object, value = nil, options = {})
        super(form, object, options)
        @value, @options = nil, value if value.is_a?(Hash)
        @value = value
        @value ||= submit_default_value
      end

      def options_for_button_html
        options.merge({class: "rounded-md bg-primary-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-primary-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"})
      end

      private

      def submit_default_value
        object = convert_to_model(@object)
        key = if object
          object.persisted? ? :update : :create
        else
          :submit
        end

        model = if object.respond_to?(:model_name)
          object.model_name.human
        else
          object_name.to_s.humanize
        end

        defaults = []
        # Object is a model and it is not overwritten by as and scope option.
        defaults << if object.respond_to?(:model_name) && object_name.to_s == model.downcase
          :"helpers.submit.#{object.model_name.i18n_key}.#{key}"
        else
          :"helpers.submit.#{object_name}.#{key}"
        end
        defaults << :"helpers.submit.#{key}"
        defaults << "#{key.to_s.humanize} #{model}"

        I18n.t(defaults.shift, model: model, default: defaults)
      end
    end
  end
end
