module FormComponents
  module SignatureField
    # A signature drawn with signature_pad
    # (vendor/javascript/form_components/signature_pad.js), sent as an SVG file
    # in Rails' file field, out of sight, for an Active Storage attachment
    # (has_one_attached :signature), as Satis' signature.
    #
    # The signature there is shown on the pad (as an image under it), and
    # stays unless one is drawn over it: the first stroke starts a new one.
    # Clear empties the pad, and removes the signature there when the record
    # takes remove_<attribute> (as a hidden field). So it needs JS. The host serves SVG as an image
    # only when it takes it out of Active Storage's
    # content_types_to_serve_as_binary.
    #
    # width: and height: the pad's size in pixels (400 × 200), its width at
    # most the field's.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[width height]

      option_reader :width, 400
      option_reader :height, 200

      # Not for a signature there is already, which isn't sent again
      def required_attribute? = false

      # Nor can the pad have aria-required
      def required_in_label? = required?

      def attachment
        object.public_send(method) if object.respond_to?(method)
      end

      # The signature there is, to show on the pad
      def url
        helpers.main_app.url_for(attachment) if attachment.respond_to?(:attached?) && attachment.attached? && attachment.blob.persisted?
      end

      def removable?
        object.respond_to?(:"remove_#{method}=")
      end

      def input
        rails(:file_field, method, input_options("hidden", from: html_options.except(:disabled, :readonly))
          .except(:"aria-invalid", :"aria-describedby", :required)
          .merge(accept: "image/svg+xml", data: {"form-components--signature-field-target": "file"}))
      end

      def remove_input
        form.hidden_field(:"remove_#{method}", value: "0", data: {"form-components--signature-field-target": "remove"}) if removable?
      end

      def field_label(id = tag_id, value: nil)
        super("#{id}_pad", id: "#{id}_label")
      end

      def read_only?
        html_options[:readonly].present? || html_options[:disabled].present?
      end

      def controller_data
        {
          controller: "form-components--signature-field",
          "form-components--signature-field-read-only-value": read_only?.to_s
        }
      end

      def pad_classes
        class_names("relative max-w-full overflow-hidden rounded-md bg-white outline outline-1 -outline-offset-1",
          {"outline-gray-300 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 auto-dark:outline-red-500/50" => has_error?})
      end

      # The menu's button and items, as an image upload's
      def more_classes
        "flex size-10 items-center justify-center rounded-full text-gray-600 hover:bg-gray-100 aria-expanded:bg-gray-100 auto-dark:text-gray-300 auto-dark:hover:bg-white/10 auto-dark:aria-expanded:bg-white/10"
      end

      def menu_item_classes
        "flex items-center gap-3 rounded-lg px-3 py-2 text-left text-gray-800 hover:bg-gray-100 auto-dark:text-gray-100 auto-dark:hover:bg-white/10"
      end

      def title(name) = I18n.t("form_components.signature_field.#{name}", default: {more: "More", undo: "Undo", clear: "Clear"}.fetch(name))
    end
  end
end
