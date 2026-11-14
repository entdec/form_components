module FormComponents
  module Submit
    # Rails' submit button, named after the record as Rails names it
    class Component < FormComponents::Base::Component
      CLASSES = "rounded-md bg-primary-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-primary-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"

      attr_reader :value

      # As Rails' submit(value = nil, options = {})
      def initialize(form, object, value = nil, options = {})
        value, options = nil, value if value.is_a?(Hash)
        super(form, object, nil, options)
        @value = value
      end

      def call
        rails(:submit, value, html_options.merge(class: helpers.class_names(CLASSES, html_options[:class])))
      end
    end
  end
end
