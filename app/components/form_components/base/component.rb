module FormComponents
  module Base
    # A form builder's field as a component. The input itself is Rails': each
    # component renders it with ActionView::Helpers::FormBuilder's own helper
    # (rails), so names, ids, values and options are exactly Rails', and adds
    # its extras around it. Its own options (extras) are taken out first.
    class Component < ViewComponent::Base
      include FormComponents::Validation

      # Options of ours, not passed on to Rails
      class_attribute :extras, default: []

      attr_reader :form, :object, :method, :options

      def initialize(form, object, method, options = {})
        @form = form
        @object = object
        @method = method
        @options = (options || {}).symbolize_keys
      end

      def self.option_reader(name, default = nil)
        define_method(name) do
          options.fetch(name, default)
        end
      end

      # The options Rails gets
      def html_options
        options.except(*extras)
      end

      # The options Rails takes the id, index: and name from: the options,
      # or html_options for helpers that have both, such as select
      def id_options
        html_options
      end

      # Renders a helper of Rails' own form builder, for this form
      def rails(helper, *, **, &)
        ActionView::Helpers::FormBuilder.instance_method(helper).bind_call(form, *, **, &)
      end

      # As Rails' label: helpers.label.<model>.<attribute>, else the
      # attribute's human name, else the method humanized
      def human_attribute_name
        ActionView::Helpers::Tags::Translator.new(object, object_name.to_s, method.to_s, scope: "helpers.label").translate ||
          method.to_s.humanize
      end

      def object_name
        form.object_name
      end

      # The id Rails gives the input, also with index:, namespace: or a value
      # (a radio button's, a check box's with multiple: true)
      def tag_id(value = nil)
        return id_options[:id] if id_options.key?(:id)

        suffix = sanitized_value(value) unless value.nil?
        form.field_id(method, *suffix, index: id_options.fetch(:index, form.options[:index]))
      end

      def name
        form.field_name(method, index: id_options.fetch(:index, form.options[:index]))
      end

      private

      # As Rails makes a value part of an id
      def sanitized_value(value)
        value.to_s.gsub(/[\s.]/, "_").gsub(/[^-[[:word:]]]/, "").downcase
      end
    end
  end
end
