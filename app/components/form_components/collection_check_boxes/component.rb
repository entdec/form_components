module FormComponents
  module CollectionCheckBoxes
    class Component < FormComponents::Field::Component
      attr_reader :collection, :value_method, :text_method, :html_options, :block
      option_reader :description_method
      def initialize(form, object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
        super(form, object, method, options)
        @collection = collection
        @value_method = value_method
        @text_method = text_method
        @html_options = html_options
        @block = block
      end
    end
  end
end
