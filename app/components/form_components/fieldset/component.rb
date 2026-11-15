module FormComponents
  module Fieldset
    # A group of fields: a fieldset with a heading (its legend) and a
    # description, the fields in a card. Not a field itself, so it needs no
    # form: f.fieldset, or rendered as it is, in any form.
    #
    #   <%= f.fieldset "Pricing", description: "What a sponsor pays" do %>
    #     <%= f.text_field :price %>
    #   <% end %>
    #
    # legend_position: puts the heading
    # - :above the card (the default), for a group in the page's main column
    # - :inside it, on its first line, for a short card, as in a side column
    # - :beside it, with the description, in a column of its own on wider
    #   screens, for settings
    #
    # A fieldset's own legend is drawn on its border, so the legend is for
    # screen readers only and the heading shown is a copy, hidden from them.
    class Component < ViewComponent::Base
      POSITIONS = %i[above inside beside].freeze

      CARD_CLASSES = "rounded-xl bg-white p-4 shadow-xs ring-1 ring-gray-900/5 sm:p-5 auto-dark:bg-white/5 auto-dark:ring-white/10"
      LEGEND_CLASSES = "text-sm/6 font-semibold text-gray-900 auto-dark:text-white"
      DESCRIPTION_CLASSES = "text-sm/6 text-gray-500 auto-dark:text-gray-400"

      attr_reader :legend, :description, :position, :html_options

      # As Rails' field_set_tag(legend = nil, options = {}), with description:
      # and legend_position:
      def initialize(legend = nil, options = {})
        @legend = legend
        @description = options[:description]
        @position = (options[:legend_position] || :above).to_sym
        raise ArgumentError, "legend_position must be one of #{POSITIONS.join(", ")}, not #{@position}" unless POSITIONS.include?(@position)

        @html_options = options.except(:description, :legend_position)
      end

      def heading?
        legend.present? || description.present?
      end

      def fieldset_options
        classes = {"inside" => CARD_CLASSES, "beside" => "grid gap-x-8 gap-y-4 md:grid-cols-3"}[position.to_s]
        aria = description.present? ? {"aria-describedby": description_id} : {}
        # Positioned, for its legend (sr-only, absolute) to be placed in it, not in the page, which it could otherwise
        # make taller
        html_options.merge(aria).merge(class: helpers.class_names("form-fieldset", "form-fieldset--#{position}", "relative", classes, html_options[:class]))
      end

      def body_classes
        helpers.class_names("form-fieldset__body grid gap-4",
          CARD_CLASSES => position != :inside,
          "mt-3" => position == :inside && heading?,
          "mt-2" => position == :above && heading?,
          "md:col-span-2" => position == :beside)
      end

      def description_id
        "#{html_options[:id] || "form_fieldset_#{object_id}"}_description"
      end
    end
  end
end
