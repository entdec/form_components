module FormComponents
  module Field
    # A field with a label, a description and its errors around Rails' input
    class Component < FormComponents::Base::Component
      self.extras = %i[label description]

      # A text, or false for no label
      option_reader :label
      # Shown below the field
      option_reader :description

      def has_error?
        all_errors.present?
      end

      def all_errors
        return [] if object.nil? || !object.respond_to?(:errors)

        if /_id$/.match?(method.to_s)
          object.errors[method].presence || object.errors[method.to_s.delete_suffix("_id").to_sym]
        else
          object.errors[method]
        end
      end

      def aria_described_by(id = tag_id)
        if has_error?
          "#{id}_error"
        elsif description.present?
          "#{id}_description"
        end
      end

      def aria_invalid
        has_error? ? "true" : "false"
      end

      # Rails' options with our classes added to the given ones, and the aria
      # attributes unless given
      def input_options(classes, id: tag_id, from: html_options)
        given_aria = from.fetch(:aria, {}).transform_keys(&:to_s)
        aria = {}
        aria["aria-invalid"] = aria_invalid unless from.key?(:"aria-invalid") || given_aria.key?("invalid")
        described_by = aria_described_by(id)
        aria["aria-describedby"] = described_by if described_by && !from.key?(:"aria-describedby") && !given_aria.key?("describedby")
        from.merge(class: helpers.class_names(classes, from[:class])).merge(aria)
      end

      # The label of the field's input, unless label: false. With a value, as
      # Rails' label(method, value:) for a radio button: also its translation.
      def field_label(id = tag_id, value: nil)
        return if label == false

        form.label(method, label.presence, {for: id, value: value}.compact)
      end
    end
  end
end
