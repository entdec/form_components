module FormComponents
  module CheckBox
    # Rails' check box, with its hidden unchecked value; with switch: true it
    # looks like a switch (role="switch"), still Rails' check box, without JS
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[switch]

      CLASSES = "col-start-1 row-start-1 size-4 appearance-none rounded border border-gray-300 bg-white auto-dark:border-white/10 auto-dark:bg-white/5 checked:border-primary-600 checked:hover:bg-primary-600 checked:bg-primary-600 indeterminate:border-primary-600 indeterminate:bg-primary-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 disabled:border-gray-300 disabled:bg-gray-100 disabled:checked:bg-gray-100 forced-colors:appearance-auto hover:ring-primary-600 focus:ring-primary-600 checked:focus:bg-primary-600"

      # The check box over the switch's track, out of sight but for its focus
      # (also without @tailwindcss/forms' check box, its colour and checkmark)
      SWITCH_CLASSES = "absolute inset-0 size-full cursor-pointer appearance-none rounded-full border-0 bg-transparent bg-none text-transparent shadow-none checked:bg-transparent checked:bg-none focus:ring-0 focus:ring-offset-0 focus:outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 disabled:cursor-not-allowed forced-colors:appearance-auto"

      attr_reader :checked_value, :unchecked_value

      option_reader :switch, false

      # As Rails' check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      def initialize(form, object, method, options = {}, checked_value = "1", unchecked_value = "0")
        super(form, object, method, options)
        @checked_value = checked_value
        @unchecked_value = unchecked_value
      end

      def input
        given = switch ? input_options(SWITCH_CLASSES, id: input_id).merge(role: "switch") : input_options(CLASSES, id: input_id)
        rails(:check_box, method, given, checked_value, unchecked_value)
      end

      # Not one of several, which would each have to be checked
      def required_attribute?
        !html_options[:multiple] && super
      end

      # With multiple: true the value is part of the id, as Rails has it
      def input_id
        tag_id(html_options[:multiple] ? checked_value : nil)
      end
    end
  end
end
