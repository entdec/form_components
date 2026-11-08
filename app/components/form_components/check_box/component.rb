module FormComponents
  module CheckBox
    class Component < FormComponents::Field::Component
      attr_reader :checked_value, :unchecked_value
      def initialize(form, object, method, options = {}, checked_value = "1", unchecked_value = "0")
        super(form, object, method, options)
        @checked_value = checked_value
        @unchecked_value = unchecked_value
      end

      def value
        checked_value
      end

      def checked?
        if object.public_send(method).respond_to?(:include?)
          object.public_send(method).include?(value)
        else
          object.public_send(method)
        end
      end

      def name
        if is_array?
          super + "[]"
        else
          super
        end
      end

      def tag_id
        [form.object_name, method, (is_array? ? value : nil)].compact_blank.join("_")
      end
    end
  end
end
