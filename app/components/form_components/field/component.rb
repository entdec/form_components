module FormComponents
  module Field
    # A field with a label, a description and its errors around Rails' input
    class Component < FormComponents::Base::Component
      self.extras = %i[label description hide_label]

      # A text, or false for no label: then the input needs a name of its own
      # (aria-label:), or a label elsewhere
      option_reader :label
      # Shown below the field
      option_reader :description
      # The label for screen readers only, out of sight
      option_reader :hide_label, false

      # Its corners: rounded, or in a field group those the group gives it,
      # for the box's corners (field_group/component.css)
      CORNERS = {
        all: ["rounded-md", "rounded-tl-(--form-group-tl) rounded-tr-(--form-group-tr) rounded-br-(--form-group-br) rounded-bl-(--form-group-bl)"],
        left: ["rounded-l-md", "rounded-tl-(--form-group-tl) rounded-bl-(--form-group-bl)"]
      }.freeze

      # In a field group (FormBuilder#field_group): its label for screen
      # readers only, its description and errors below the group, its
      # outline on its neighbours' and its corners the group's
      def grouped?
        form.respond_to?(:grouped_fields) && !form.grouped_fields.nil?
      end

      def before_render
        form.grouped_fields << self if grouped?
        super
      end

      def corner_classes(side = :all)
        CORNERS.fetch(side)[grouped? ? 1 : 0]
      end

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

      # The errors, then the description: both are read with the input
      def aria_described_by(id = tag_id)
        ids = []
        ids << "#{id}_error" if has_error?
        ids << "#{id}_description" if description.present?
        ids.join(" ").presence
      end

      def aria_invalid
        has_error? ? "true" : "false"
      end

      # Whether the input gets the required attribute, for the browser to
      # check: when its attribute must be filled in now (required_now?)
      def required_attribute?
        required_now?
      end

      # Whether the label says it's required for screen readers too, besides
      # its asterisk, for an input that can't have aria-required (a radio
      # button, a file field, a button) or doesn't get required. The others
      # get aria-required instead.
      def required_in_label?
        false
      end

      # Required, but not for the browser to check (required_attribute?), as
      # its asterisk says
      def aria_required?
        required? && !required_attribute? && !required_in_label?
      end

      # Rails' options with our classes added to the given ones, and the aria
      # attributes and required unless given
      def input_options(classes, id: tag_id, from: html_options)
        given_aria = from.fetch(:aria, {}).transform_keys(&:to_s)
        aria = {}
        aria[:required] = true if !from.key?(:required) && required_attribute?
        aria["aria-required"] = "true" if !from.key?(:required) && !from.key?(:"aria-required") && !given_aria.key?("required") && aria_required?
        aria["aria-invalid"] = aria_invalid unless from.key?(:"aria-invalid") || given_aria.key?("invalid")
        described_by = aria_described_by(id)
        aria["aria-describedby"] = described_by if described_by && !from.key?(:"aria-describedby") && !given_aria.key?("describedby")
        from.merge(class: helpers.class_names(classes, from[:class])).merge(aria)
      end

      # The label of the field's input, unless label: false. With a value, as
      # Rails' label(method, value:) for a radio button: also its translation.
      def field_label(id = tag_id, value: nil, **more)
        return if label == false

        form.label(method, label.presence, {for: id, value: value}.compact.merge(label_options, more))
      end

      # What the label gets of ours: sr-only with hide_label: or in a group,
      # and whether it
      # says the input is required (required_in_label?)
      def label_options
        {class: ("sr-only" if hide_label || grouped?), required_text: (true if required_in_label?)}.compact
      end
    end
  end
end
