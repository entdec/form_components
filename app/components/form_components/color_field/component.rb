module FormComponents
  module ColorField
    # A color as "#rrggbb", picked with JS Color Picker (vendor/javascript/form_components/jscolorpicker). It can be cleared,
    # so leaving it empty can mean "the default color".
    class Component < FormComponents::Field::Component
      # Colors to pick from with one click, like those of a logo
      option_reader :swatches, []
      # The color used while the field is empty, shown in it then
      option_reader :default
      # Shown in the field while it's empty and there's no default
      option_reader :placeholder

      def default_color
        default if default.to_s.match?(/\A#\h{6}\z/)
      end

      def placeholder_text
        default_color || placeholder
      end

      def options_for_input_html
        options.except(:label, :placeholder, :type, :description, :swatches, :default)
      end
    end
  end
end
