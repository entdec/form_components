module FormComponents
  module CollectionCheckBoxes
    # Rails' collection_check_boxes, see Collection
    class Component < FormComponents::Collection::Component
      def helper = :collection_check_boxes

      def input_helper = :check_box

      def input_classes = FormComponents::CheckBox::Component::CLASSES
    end
  end
end
