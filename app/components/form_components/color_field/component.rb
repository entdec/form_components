module FormComponents
  module ColorField
    # A color as "#rrggbb", picked with JS Color Picker (vendor/javascript/form_components/jscolorpicker).
    #
    # Unlike Rails' color_field, the input is a text field (Rails' text_field,
    # so its name, id and options are Rails'), for the picker, and it can be
    # cleared: an empty value stays empty, where Rails would send #000000, so
    # leaving it empty can mean "the default color".
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[swatches default]

      # Colors to pick from with one click, like those of a logo
      option_reader :swatches, []
      # The color used while the field is empty, shown in it then
      option_reader :default

      def default_color
        default if default.to_s.match?(/\A#\h{6}\z/)
      end

      def input
        rails(:text_field, method, input_options(nil).merge(placeholder: default_color || html_options[:placeholder], data: (html_options[:data] || {}).merge("form-components--color-field-target": "input")).compact)
      end
    end
  end
end
