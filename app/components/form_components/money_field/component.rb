module FormComponents
  module MoneyField
    # An amount with its currency, for money-rails' monetize: the amount in
    # Rails' text field (inputmode decimal), with the currency's symbol before
    # it, and the currency in Rails' select at its end, for the currency's
    # attribute ("amount_currency" for :amount), in one field:
    #
    #   <%= f.money_field :amount, currencies: %w[EUR USD GBP] %>
    #
    # The symbols are the money gem's (Money::Currency), kept up to date with
    # the currency picked by the controller; without the gem there are none.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[currency_method currencies default_currency corner_hint]

      # The currency when the record has none
      class_attribute :default_currency, default: "EUR"
      # The currencies to pick from, Rails' select's choices; nil for all of
      # the money gem's, else these
      class_attribute :default_currencies, default: nil

      # Next to the label, above the field
      option_reader :corner_hint

      def currency_method
        options.fetch(:currency_method, "#{method}_currency").to_sym
      end

      def currencies
        options[:currencies] || self.class.default_currencies ||
          (defined?(Money::Currency) ? Money::Currency.all.map(&:iso_code) : %w[EUR USD GBP])
      end

      def selected_currency
        currency = object.public_send(currency_method) if object.respond_to?(currency_method)
        (currency.presence || options.fetch(:default_currency, default_currency)).to_s.upcase
      end

      # Each currency's symbol, by its code, for those the money gem knows
      def symbols
        return {} unless defined?(Money::Currency)

        @symbols ||= currencies.map { |choice| Array(choice).last.to_s.upcase }.filter_map do |code|
          symbol = Money::Currency.find(code)&.symbol
          [code, symbol] if symbol.present?
        end.to_h
      end

      def symbol = symbols[selected_currency]

      # The amount's errors and the currency's
      def all_errors
        errors = super
        return errors if object.nil? || !object.respond_to?(:errors)

        errors + object.errors[currency_method]
      end

      def input
        given = input_options(input_classes)
        rails(:text_field, method, given.merge(inputmode: given.fetch(:inputmode, "decimal"), placeholder: given.fetch(:placeholder) { placeholder }))
      end

      def currency_select
        rails(:select, currency_method, currencies, {selected: selected_currency},
          html_options.slice(:index, :form, :disabled).merge(class: select_classes, aria: {label: currency_label, invalid: aria_invalid},
            data: {"form-components--money-field-target": "currency", action: "form-components--money-field#update"}))
      end

      # Zero, as the locale writes it, with the currency's decimals
      def placeholder
        decimals = (defined?(Money::Currency) && Money::Currency.find(selected_currency)&.exponent) || 2
        helpers.number_with_precision(0, precision: decimals)
      end

      def wrapper_classes
        class_names("flex items-center rounded-md bg-white outline outline-1 -outline-offset-1 has-[input:focus]:outline-2 has-[input:focus]:-outline-offset-1 auto-dark:bg-white/5",
          {"outline-gray-300 has-[input:focus]:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 has-[input:focus]:outline-red-600 auto-dark:outline-red-500/50" => has_error?})
      end

      def input_classes
        class_names("block min-w-0 grow border-0 bg-transparent py-1.5 pr-3 text-base placeholder:text-gray-500 focus:outline-none focus:ring-0 sm:text-sm/6 auto-dark:placeholder:text-gray-400",
          symbols.any? ? "pl-1" : "pl-3",
          {"text-gray-900 auto-dark:text-white" => !has_error?},
          {"text-red-900 placeholder:text-red-300 auto-dark:text-red-300" => has_error?})
      end

      def select_classes
        "shrink-0 rounded-md border-0 bg-transparent py-1.5 pr-8 pl-3 text-base text-gray-500 focus:outline-2 focus:-outline-offset-2 focus:outline-primary-600 focus:ring-0 disabled:cursor-not-allowed sm:text-sm/6 auto-dark:text-gray-400 auto-dark:*:bg-gray-800"
      end

      def currency_label = I18n.t("form_components.money_field.currency", default: "Currency")
    end
  end
end
