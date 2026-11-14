module FormComponents
  module CheckBox
    # Rails' check box, with its hidden unchecked value
    class Component < FormComponents::Field::Component
      CLASSES = "col-start-1 row-start-1 size-4 appearance-none rounded border border-gray-300 bg-white auto-dark:border-white/10 auto-dark:bg-white/5 checked:border-primary-600 checked:hover:bg-primary-600 checked:bg-primary-600 indeterminate:border-primary-600 indeterminate:bg-primary-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 disabled:border-gray-300 disabled:bg-gray-100 disabled:checked:bg-gray-100 forced-colors:appearance-auto hover:ring-primary-600 focus:ring-primary-600 checked:focus:bg-primary-600"

      attr_reader :checked_value, :unchecked_value

      # As Rails' check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      def initialize(form, object, method, options = {}, checked_value = "1", unchecked_value = "0")
        super(form, object, method, options)
        @checked_value = checked_value
        @unchecked_value = unchecked_value
      end

      def input
        rails(:check_box, method, input_options(CLASSES, id: input_id), checked_value, unchecked_value)
      end

      # With multiple: true the value is part of the id, as Rails has it
      def input_id
        tag_id(html_options[:multiple] ? checked_value : nil)
      end
    end
  end
end
