module FormComponents
  module Collection
    # Rails' collection_check_boxes or collection_radio_buttons in a fieldset,
    # its label as the legend, with the description and errors once. Each
    # item is Rails' check box or radio button and label, with the item's own
    # description (description_method), unless a block renders the items, as
    # with Rails.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[description_method]

      # Of an item, as value_method and text_method: a method name or a proc
      option_reader :description_method

      attr_reader :collection, :value_method, :text_method, :item_html_options, :block

      # As Rails' collection helpers: (method, collection, value_method, text_method, options = {}, html_options = {}, &block)
      def initialize(form, object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
        super(form, object, method, options)
        @collection = collection
        @value_method = value_method
        @text_method = text_method
        @item_html_options = (html_options || {}).symbolize_keys
        @block = block
      end

      def items
        each_item = block || ->(builder) { item(builder) }
        rails(helper, method, collection, value_method, text_method, html_options, item_html_options, &each_item)
      end

      def legend
        safe_join([label.presence || human_attribute_name, (tag.span(class: "fas fa-asterisk fa-xs text-red-500 ml-1", aria: {hidden: true}) if required?)])
      end

      def legend_classes
        FormComponents::Label::Component::CLASSES
      end

      def items_classes
        "space-y-2"
      end

      # Shown below the items
      def after_items
      end

      private

      def item(builder)
        id = tag_id(builder.value)
        description = item_description(builder.object)
        aria = {"aria-invalid" => aria_invalid}
        aria["aria-describedby"] = "#{id}_description" if description.present?
        input = builder.public_send(input_helper, aria.merge(class: helpers.class_names(input_classes, item_html_options[:class])))

        tag.div(class: "relative flex items-start") do
          safe_join([
            tag.div(input, class: "flex h-6 items-center"),
            tag.div(class: "ml-3 text-sm/6") do
              safe_join([
                builder.label(class: FormComponents::Label::Component::CLASSES),
                (tag.label(description, for: id, id: "#{id}_description", class: "text-gray-500 auto-dark:text-gray-400") if description.present?)
              ])
            end
          ])
        end
      end

      def item_description(item)
        return if description_method.blank?

        description_method.respond_to?(:call) ? description_method.call(item) : item.public_send(description_method)
      end
    end
  end
end
