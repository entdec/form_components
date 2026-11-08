module FormComponents
  module Base
    class Component < ViewComponent::Base
      include FormComponents::Validation

      attr_reader :form, :object, :method, :options

      def initialize(form, object, method, options = {})
        @form = form
        @object = object
        @method = method
        @options = options
      end

      def human_attribute_name
        object.class.human_attribute_name(method)
      end

      def self.option_reader(name, default = nil)
        define_method(name) do
          options.fetch(name, default)
        end
      end

      def object_name
        form.object_name
      end

      def name
        "#{form.object_name}[#{method}]"
      end

      def tag_id
        [form.object_name, method].compact_blank.join("_")
      end

      def is_array?
        object.class.try(:column_for_attribute, method).try(:array?)
      end
    end
  end
end
