module FormComponents
  module RadioButton
    class Component < FormComponents::Field::Component
      attr_reader :tag_value
      def initialize(form, object, method, tag_value, options = {})
        super(form, object, method, options)
        @tag_value = tag_value
      end

      def value
        tag_value
      end

      # The value is often a symbol, like a state's name, and the attribute a string
      def checked?
        current = object.public_send(method)
        current.is_a?(Array) ? current.map(&:to_s).include?(value.to_s) : current.to_s == value.to_s
      end

      def name
        if is_array?
          super + "[]"
        else
          super
        end
      end

      def tag_id
        # [form.object_name, method, (is_array? ? value : nil)].compact_blank.join("_")
        [form.object_name, method, tag_value].compact_blank.join("_")
      end
    end
  end
end
