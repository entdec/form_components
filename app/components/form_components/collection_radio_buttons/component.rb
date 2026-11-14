module FormComponents
  module CollectionRadioButtons
    # Rails' collection_radio_buttons, see Collection
    class Component < FormComponents::Collection::Component
      def helper = :collection_radio_buttons

      def input_helper = :radio_button

      def input_classes = FormComponents::RadioButton::Component::CLASSES
    end
  end
end
