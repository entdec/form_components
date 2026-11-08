module FormComponents
  module Label
    class Component < FormComponents::Base::Component
      attr_reader :text
      option_reader :value
      def initialize(form, object, method_name, text = nil, options = {})
        @text = text
        super(form, object, method_name, options)
      end

      def tag_id
        [form.object_name, method, value].compact_blank.join("_")
      end
    end
  end
end
