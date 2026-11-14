module FormComponents
  module RatingField
    # Stars to rate with, 1 to max: (5 unless given): Rails'
    # collection_radio_buttons of their numbers, a star for each. A star
    # lights up when its number or a higher one is checked or hovered.
    class Component < FormComponents::CollectionRadioButtons::Component
      self.extras = superclass.extras + %i[max]

      ITEM_CLASSES = "cursor-pointer text-gray-300 hover:text-amber-300 [&:has(~label:hover)]:text-amber-300 [&:has(~input:checked)]:text-amber-400 auto-dark:text-white/20"

      STAR = "M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z"

      # As FormBuilder#rating_field(method, options = {})
      def initialize(form, object, method, options = {})
        options = (options || {}).symbolize_keys
        super(form, object, method, (1..options.fetch(:max, 5)).to_a, :itself, :itself, options)
      end

      def items_classes
        "flex w-fit gap-1 rounded-md has-[:focus-visible]:outline has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-primary-600"
      end

      private

      # Its label first, so a star can see the inputs after it
      def item(builder)
        input = builder.radio_button(class: "sr-only", "aria-invalid": aria_invalid)
        label = builder.label(class: ITEM_CLASSES) do
          safe_join([star, tag.span(builder.text, class: "sr-only")])
        end
        safe_join([label, input])
      end

      def star
        tag.svg(tag.path(d: STAR, "fill-rule": "evenodd", "clip-rule": "evenodd"), viewBox: "0 0 24 24", fill: "currentColor", class: "size-8", aria: {hidden: true})
      end
    end
  end
end
