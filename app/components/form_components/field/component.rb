module FormComponents
  module Field
    class Component < FormComponents::Base::Component
      # String or false, if false, no label will be rendered, if string it will be used as label text
      option_reader :label
      # Adds a description below the text field
      option_reader :description

      def value
        if respond_to?(:type) && type == :"datetime-local"
          object.public_send(method)&.localtime(Time.zone)&.strftime("%Y-%m-%dT%H:%M")
        else
          object.public_send(method)
        end
      end

      def has_error?
        return if object.blank?

        all_errors.present?
      end

      def all_errors
        return if object.blank?

        if /_id$/.match?(method.to_s)
          object.errors[method].presence || object.errors[method.to_s.gsub(/_id$/, "").to_sym]
        else
          object.errors[method]
        end
      end

      def aria_described_by
        if has_error?
          tag_id + "_error"
        elsif description.present?
          tag_id + "_description"
        end
      end

      def aria_invalid
        has_error? ? "true" : "false"
      end

      # Returns options hash for a collection item
      def options_for_collection_item(item)
        item_options = {}
        item_options[:label] = item.public_send(value_method) if text_method.present?
        item_options[:description] = item.public_send(description_method) if description_method.present?
        options.merge(item_options)
      end

      # Returns options for HTML input tag
      def options_for_input_html
        options.except(:label, :placeholder, :type, :description)
      end
    end
  end
end
