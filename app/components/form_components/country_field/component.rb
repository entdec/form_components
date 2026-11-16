module FormComponents
  module CountryField
    # A country picked from a list with their flags and names, searched as
    # typed, as the telephone field's, sent as its ISO 3166 code in capitals
    # ("NL") in Rails' hidden field; a code in any case is read. The names
    # are the browser's, in the locale (Intl.DisplayNames), so it needs JS.
    # Without required, it can be cleared.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[priority_countries corner_hint placeholder]

      # The countries at the top of the list
      class_attribute :default_priority_countries, default: %w[nl de be fr gb]

      # The countries, by their ISO 3166 codes
      COUNTRIES = FormComponents::TelephoneField::Component::CALLING_CODES.keys.freeze

      # Next to the label, above the field
      option_reader :corner_hint

      def priority_countries
        Array(options.fetch(:priority_countries, default_priority_countries)).map { |code| code.to_s.downcase } & COUNTRIES
      end

      def value
        html_options.key?(:value) ? html_options[:value] : object&.public_send(method)
      end

      # The country there is, if it's one of ours
      def country
        code = value.to_s.downcase
        code if COUNTRIES.include?(code)
      end

      def placeholder = options[:placeholder] || I18n.t("form_components.country_field.placeholder", default: "Choose a country")

      def search_placeholder = I18n.t("form_components.country_field.search", default: "Search")

      def clear_label = I18n.t("form_components.country_field.clear", default: "Clear")

      def clearable? = !required_attribute? && !html_options[:disabled]

      # Its toggle, a button, can't have aria-required
      def required_in_label? = required?

      # Named by the label and the country picked (or the placeholder), which
      # a label alone would leave out
      def field_label(id = tag_id, value: nil)
        super(id, id: "#{id}_label")
      end

      def hidden_input
        rails(:hidden_field, method, html_options.slice(:index, :name, :form, :disabled, :data).merge(id: nil, value: country&.upcase,
          data: (html_options[:data] || {}).merge("form-components--country-field-target": "value", action: "change->form-components--country-field#changed")))
      end

      def toggle_attributes
        given = input_options(toggle_classes, from: html_options.except(:name, :value, :data, :index, :form))
        given.except(:required, :"aria-required").merge(type: "button", id: tag_id, "aria-haspopup": "listbox", "aria-expanded": "false",
          "aria-labelledby": [("#{tag_id}_label" unless label == false), "#{tag_id}_value"].compact.join(" "),
          data: {"form-components--country-field-target": "toggle", action: "form-components--country-field#toggle keydown->form-components--country-field#toggleKeydown"})
      end

      def toggle_classes
        class_names("flex w-full items-center gap-2 rounded-md bg-white py-1.5 pr-3 pl-3 text-left text-base outline outline-1 -outline-offset-1 focus-visible:outline-2 focus-visible:-outline-offset-1 disabled:cursor-not-allowed sm:text-sm/6 auto-dark:bg-white/5",
          {"text-gray-900 outline-gray-300 focus-visible:outline-primary-600 auto-dark:text-white auto-dark:outline-white/10" => !has_error?},
          {"text-red-900 outline-red-300 focus-visible:outline-red-600 auto-dark:text-red-300 auto-dark:outline-red-500/50" => has_error?})
      end
    end
  end
end
