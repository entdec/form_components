module FormComponents
  module FieldGroup
    # Fields in one box, as a card's number, expiry and CVC: a fieldset with
    # its legend as their label, each field below the one before, or in a
    # field_row beside each other. The fields' own labels are for screen
    # readers only (their placeholders show what goes where), and their
    # descriptions and errors are below the box, with their ids, so they
    # still describe their inputs.
    #
    #   <%= f.field_group "Card details" do %>
    #     <%= f.text_field :number, placeholder: "Card number" %>
    #     <%= f.field_row do %>
    #       <%= f.text_field :expiry, placeholder: "MM / YY" %>
    #       <%= f.text_field :cvc, placeholder: "CVC" %>
    #     <% end %>
    #   <% end %>
    #
    # The text fields, text areas, selects, and the country, telephone and
    # money fields can be in one.
    class Component < ViewComponent::Base
      attr_reader :legend, :fields, :description, :html_options

      # As Rails' field_set_tag(legend = nil, options = {}), with
      # description:, given the fields rendered in it
      def initialize(legend, fields, options = {})
        @legend = legend
        @fields = fields
        @description = options[:description]
        @html_options = options.except(:description)
      end

      def fieldset_options
        aria = description.present? ? {"aria-describedby": description_id} : {}
        html_options.merge(aria).merge(class: helpers.class_names("form-group", html_options[:class]))
      end

      # Marked as a field's label is, when one of them is required
      def required?
        fields.any?(&:required?)
      end

      def description_id
        "#{html_options[:id] || "form_group_#{object_id}"}_description"
      end
    end
  end
end
