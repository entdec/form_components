module FormComponents
  module Label
    # Rails' label, with its text marked when the attribute is required
    class Component < FormComponents::Base::Component
      CLASSES = "block text-sm/6 font-medium text-gray-900 auto-dark:text-white"

      attr_reader :text, :block

      # As Rails' label(method, text = nil, options = {}, &block)
      def initialize(form, object, method, text = nil, options = {}, &block)
        text, options = nil, text if text.is_a?(Hash)
        super(form, object, method, options)
        @text = text
        @block = block
      end

      def call
        rails(:label, method, text, html_options.merge(class: helpers.class_names(CLASSES, html_options[:class]))) do |builder|
          content = block ? helpers.capture(builder, &block) : (text.presence || builder.translation)
          safe_join([content, (asterisk if required?)])
        end
      end

      private

      def asterisk
        tag.span(class: "fas fa-asterisk fa-xs text-red-500 ml-1", aria: {hidden: true})
      end
    end
  end
end
