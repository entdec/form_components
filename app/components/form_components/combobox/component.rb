module FormComponents
  module Combobox
    # hotwire_combobox's combobox (form.combobox), with our label above it:
    # its own stays hidden, as it is without a label: text
    class Component < FormComponents::Field::Component
      attr_reader :options_or_src, :block

      # As hotwire_combobox's combobox(method, options_or_src = [], **options, &block)
      def initialize(form, object, method, options_or_src = [], options = {}, &block)
        super(form, object, method, options)
        @options_or_src = options_or_src
        @block = block
      end

      # Its own options, with the aria attributes; a class given replaces its
      # input's, as with hotwire_combobox
      def input
        given = input_options(nil)
        given.delete(:class) if html_options[:class].blank?
        rails(:combobox, method, options_or_src, **given, &block)
      end

      def tag_id(value = nil)
        html_options[:id] || form.field_id(method)
      end
    end
  end
end
