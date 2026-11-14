module FormComponents
  module RadioButton
    # Rails' radio button
    class Component < FormComponents::Field::Component
      CLASSES = "relative size-4 appearance-none rounded-full border border-gray-300 bg-white before:absolute before:inset-1 before:rounded-full before:bg-white auto-dark:border-white/10 auto-dark:bg-white/5 checked:border-primary-600 checked:hover:bg-primary-600 checked:bg-primary-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 disabled:border-gray-300 disabled:bg-gray-100 disabled:before:bg-gray-400 forced-colors:appearance-auto forced-colors:before:hidden [&:not(:checked)]:before:hidden hover:ring-primary-600 focus:ring-primary-600 focus:bg-primary-600 checked:focus:bg-primary-600"

      attr_reader :tag_value

      # As Rails' radio_button(method, tag_value, options = {})
      def initialize(form, object, method, tag_value, options = {})
        super(form, object, method, options)
        @tag_value = tag_value
      end

      def input
        rails(:radio_button, method, tag_value, input_options(CLASSES, id: input_id))
      end

      def input_id
        tag_id(tag_value)
      end
    end
  end
end
