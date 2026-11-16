module FormComponents
  module MoneyField
    # An amount with its currency, for money-rails' monetize: the currency
    # picked at the field's start, from a list with their names in the locale
    # (the browser's), searched as typed, as the telephone field's countries,
    # then the amount in Rails' text field (inputmode decimal). The currency
    # is sent in Rails' hidden field for its attribute ("amount_currency" for
    # :amount), kept up to date by the controller, so picking one needs JS:
    #
    #   <%= f.money_field :amount, currencies: %w[EUR USD GBP] %>
    #
    # The currency is shown by its symbol, the money gem's (Money::Currency),
    # or with currency_display: :code by its code; one without a symbol (all
    # of them without the gem) by its code.
    #
    # With fixed_currency: true the currency is shown, not picked: instead of
    # the toggle, describing the amount, and sent as it is.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[currency_method currencies priority_currencies default_currency fixed_currency currency_display corner_hint]

      # The currency when the record has none
      class_attribute :default_currency, default: "EUR"
      # The currencies to pick from, by their codes; nil for all of the money
      # gem's, else these
      class_attribute :default_currencies, default: nil
      # The currencies at the top of the list
      class_attribute :default_priority_currencies, default: %w[EUR USD GBP]
      # How the currency is shown, :symbol or :code
      class_attribute :default_currency_display, default: :symbol

      # Next to the label, above the field
      option_reader :corner_hint
      # The currency shown, not picked
      option_reader :fixed_currency, false

      def currency_method
        options.fetch(:currency_method, "#{method}_currency").to_sym
      end

      def currency_display
        options.fetch(:currency_display, default_currency_display).to_sym
      end

      def currencies
        options[:currencies] || self.class.default_currencies ||
          (defined?(Money::Currency) ? Money::Currency.all.map(&:iso_code) : %w[EUR USD GBP])
      end

      # The codes to pick from, with the record's, also when it isn't one of
      # them
      def currency_codes
        @currency_codes ||= currencies.map { |code| code.to_s.upcase } | [selected_currency]
      end

      def priority_currencies
        Array(options.fetch(:priority_currencies, default_priority_currencies)).map { |code| code.to_s.upcase } & currency_codes
      end

      def selected_currency
        currency = object.public_send(currency_method) if object.respond_to?(currency_method)
        (currency.presence || options.fetch(:default_currency, default_currency)).to_s.upcase
      end

      # A currency as it's shown: its symbol, if the money gem knows it, or
      # its code
      def display(code)
        symbol = Money::Currency.find(code)&.symbol if currency_display == :symbol && defined?(Money::Currency)
        symbol.presence || code
      end

      # The picker's countries: each currency's code in lowercase, with how
      # it's shown
      def picker_currencies
        currency_codes.map { |code| [code.downcase, display(code)] }
      end

      def picker_data
        {controller: "form-components--money-field", "form-components--money-field-countries-value": picker_currencies.to_json,
         "form-components--money-field-priority-value": priority_currencies.map(&:downcase).to_json,
         "form-components--money-field-country-value": selected_currency.downcase, "form-components--money-field-locale-value": I18n.locale,
         action: "click@document->form-components--money-field#clickOutside"}
      end

      # The amount's errors and the currency's
      def all_errors
        errors = super
        return errors if object.nil? || !object.respond_to?(:errors)

        errors + object.errors[currency_method]
      end

      # A fixed currency describes the amount too
      def aria_described_by(id = tag_id)
        return super unless fixed_currency && id == tag_id

        [super, "#{id}_currency_display"].compact.join(" ")
      end

      def input
        given = input_options(input_classes)
        rails(:text_field, method, given.merge(inputmode: given.fetch(:inputmode, "decimal"), placeholder: given.fetch(:placeholder) { placeholder },
          data: (given[:data] || {}).merge("form-components--money-field-target": "amount")))
      end

      def currency_hidden_input
        rails(:hidden_field, currency_method, html_options.slice(:index, :form, :disabled).merge(value: selected_currency,
          data: {"form-components--money-field-target": "value"}))
      end

      # Zero, as the locale writes it, with the currency's decimals
      def placeholder
        decimals = (defined?(Money::Currency) && Money::Currency.find(selected_currency)&.exponent) || 2
        helpers.number_with_precision(0, precision: decimals)
      end

      def wrapper_classes
        class_names("flex bg-white outline outline-1 -outline-offset-1 focus-within:outline-2 focus-within:-outline-offset-1 auto-dark:bg-white/5",
          corner_classes,
          {"focus-within:relative" => grouped?, "relative" => grouped? && has_error?},
          {"outline-gray-300 focus-within:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 focus-within:outline-red-600 auto-dark:outline-red-500/50" => has_error?})
      end

      def input_classes
        class_names("block min-w-0 grow border-0 bg-transparent px-3 py-1.5 text-base placeholder:text-gray-500 focus:outline-none focus:ring-0 sm:text-sm/6 auto-dark:placeholder:text-gray-400",
          {"text-gray-900 auto-dark:text-white" => !has_error?},
          {"text-red-900 placeholder:text-red-300 auto-dark:text-red-300" => has_error?})
      end

      def currency_label = I18n.t("form_components.money_field.currency", default: "Currency")

      def search_placeholder = I18n.t("form_components.money_field.search", default: "Search")
    end
  end
end
