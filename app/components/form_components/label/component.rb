module FormComponents
  module Label
    # Rails' label, with its text marked when the attribute is required: an
    # asterisk, and with required_text: true also the word, for screen
    # readers, for an input that can't say it's required itself
    class Component < FormComponents::Base::Component
      self.extras = %i[required required_text]

      CLASSES = "block text-sm/6 font-medium text-gray-900 auto-dark:text-white"

      option_reader :required_text, false
      # Given by its field (Field#required?), which knows better than the
      # validators: whether it's locked, or required: was given
      option_reader :required

      def required?(context: validation_context)
        required.nil? ? super : required
      end

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
          safe_join([content, (asterisk(required_text: required_text) if required?)])
        end
      end
    end
  end
end
