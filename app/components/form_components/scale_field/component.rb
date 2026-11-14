module FormComponents
  module ScaleField
    # A scale to pick a number on, in: 1..5 unless given, with min_label: and
    # max_label: at its ends: Rails' collection_radio_buttons of its numbers,
    # as buttons
    class Component < FormComponents::CollectionRadioButtons::Component
      self.extras = superclass.extras + %i[in min_label max_label]

      option_reader :min_label
      option_reader :max_label

      ITEM_CLASSES = "flex h-10 cursor-pointer items-center justify-center rounded-md bg-white text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 peer-checked:bg-primary-600 peer-checked:text-white peer-checked:ring-0 peer-checked:hover:bg-primary-700 peer-focus-visible:outline peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-primary-600 auto-dark:bg-white/5 auto-dark:text-white auto-dark:ring-white/10 auto-dark:hover:bg-white/10"

      # As FormBuilder#scale_field(method, options = {})
      def initialize(form, object, method, options = {})
        options = (options || {}).symbolize_keys
        super(form, object, method, numbers(options), :itself, :itself, options)
      end

      def items_classes
        "flex gap-1"
      end

      def after_items
        return if min_label.blank? && max_label.blank?

        tag.div(class: "mt-2 flex justify-between gap-4 text-sm text-gray-500 auto-dark:text-gray-400") do
          safe_join([tag.span(min_label), tag.span(max_label, class: "text-right")])
        end
      end

      private

      def numbers(options)
        options.fetch(:in, 1..5).to_a
      end

      def item(builder)
        input = builder.radio_button(class: "peer sr-only", "aria-invalid": aria_invalid)
        tag.div(safe_join([input, builder.label(class: ITEM_CLASSES)]), class: "min-w-0 flex-1")
      end
    end
  end
end
