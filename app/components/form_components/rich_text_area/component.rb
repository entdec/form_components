module FormComponents
  module RichTextArea
    # A Tiptap editor (vendor/javascript/form_components/tiptap.js) instead of
    # Rails' Trix, for an Action Text attribute (has_rich_text) or one that
    # holds HTML.
    #
    # The HTML is in Rails' text_area, with its name, id and options, out of
    # sight: the controller keeps it up to date, the label points at it and the
    # browser checks it when it's required, and it hands its focus to the
    # editor. So like the color field it needs JS.
    #
    # toolbar: the buttons, as names from BUTTONS and :heading (a select of
    # paragraph and headings), with :| between groups; false for none. The
    # editor allows only the formatting they have, also when pasting or typing
    # Markdown. :image uploads an image with Active Storage's direct uploads,
    # also when one is pasted or dropped, and only when the host has Active
    # Storage's routes (or data: {direct_upload_url:, blob_url_template:},
    # as Rails takes). An Action Text attribute's images are attachments,
    # others an <img> with the blob's URL. Other attachments of an Action Text
    # attribute, from Trix, are left out.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[corner_hint toolbar placeholder]

      # The buttons of every rich text area, unless toolbar: is given
      class_attribute :default_toolbar, default: %i[heading | bold italic underline strike | link | bullet_list ordered_list blockquote | image | undo redo]

      # Each button's icon (Font Awesome)
      BUTTONS = {
        bold: "fas fa-bold", italic: "fas fa-italic", underline: "fas fa-underline", strike: "fas fa-strikethrough",
        code: "fas fa-code", link: "fas fa-link", bullet_list: "fas fa-list-ul", ordered_list: "fas fa-list-ol",
        blockquote: "fas fa-quote-right", code_block: "fas fa-file-code", horizontal_rule: "fas fa-minus",
        align_left: "fas fa-align-left", align_center: "fas fa-align-center", align_right: "fas fa-align-right",
        align_justify: "fas fa-align-justify", image: "fas fa-image", undo: "fas fa-rotate-left", redo: "fas fa-rotate-right"
      }.freeze

      # The heading levels of the :heading select
      HEADING_LEVELS = [1, 2, 3].freeze

      # Next to the label, above the field
      option_reader :corner_hint
      # Shown while it's empty
      option_reader :placeholder

      # The toolbar's names, without :image when there's nowhere to upload to,
      # and without separators at the ends or next to each other
      def toolbar
        names = options.fetch(:toolbar, default_toolbar)
        return [] if names == false

        names = names.map(&:to_sym)
        unknown = names - BUTTONS.keys - %i[heading |]
        raise ArgumentError, "Unknown rich text area buttons: #{unknown.join(", ")}" if unknown.any?

        names -= [:image] unless uploads?
        names = names.each_with_object([]) { |name, kept| kept << name unless name == :| && kept.last.in?([nil, :|]) }
        (names.last == :|) ? names[0...-1] : names
      end

      # The toolbar in groups, between the separators
      def toolbar_groups
        toolbar.chunk { |name| (name == :|) ? :_separator : true }.map(&:last)
      end

      def title(name) = I18n.t("form_components.rich_text_area.#{name}", default: name.to_s.humanize)

      def heading_label(level) = I18n.t("form_components.rich_text_area.heading_level", level: level, default: "Heading %{level}")

      def paragraph_label = I18n.t("form_components.rich_text_area.paragraph", default: "Paragraph")

      def link_label = I18n.t("form_components.rich_text_area.url", default: "URL")

      def apply_label = I18n.t("form_components.rich_text_area.apply", default: "Apply")

      def remove_link_label = I18n.t("form_components.rich_text_area.remove_link", default: "Remove link")

      def uploads?
        direct_upload_url.present? && blob_url_template.present?
      end

      def direct_upload_url
        data_option(:direct_upload_url) { main_app.rails_direct_uploads_url if main_app.respond_to?(:rails_direct_uploads_url) }
      end

      def blob_url_template
        data_option(:blob_url_template) { main_app.rails_service_blob_url(":signed_id", ":filename") if main_app.respond_to?(:rails_service_blob_url) }
      end

      def action_text?
        defined?(ActionText::RichText) && raw_value.is_a?(ActionText::RichText)
      end

      # The HTML to edit: an Action Text attribute's with its images as
      # <img data-sgid>, which the controller turns back into attachments
      def value
        return html_options[:value] if html_options.key?(:value)
        return raw_value unless action_text?

        content = raw_value.body or return
        content.render_attachments do |attachment|
          blob = attachment.attachable
          if blob.is_a?(ActiveStorage::Blob) && blob.image?
            helpers.tag.img(src: blob_url(blob), alt: attachment.caption.presence, data: {sgid: blob.attachable_sgid, content_type: blob.content_type, filename: blob.filename.to_s})
          else
            ""
          end
        end.to_html
      end

      # Rails' text area, with the HTML, out of sight
      def input
        given = input_options("pointer-events-none absolute bottom-0 left-1/2 size-px resize-none opacity-0", from: html_options.except(:class, :data, :value))
        data = (html_options[:data] || {}).symbolize_keys.except(:direct_upload_url, :blob_url_template)
        rails(:text_area, method, given.except(:"aria-invalid", :"aria-describedby").merge(value: value, tabindex: -1, "aria-hidden": "true",
          data: data.merge("form-components--rich-text-area-target": "input", action: "focus->form-components--rich-text-area#focus invalid->form-components--rich-text-area#focus")))
      end

      def field_label(id = tag_id, value: nil)
        return if label == false

        form.label(method, label.presence, for: id, id: "#{id}_label")
      end

      # The editor's own attributes, for the controller to give it
      def editor_attributes
        required = html_options.key?(:required) ? html_options[:required] : required_attribute?
        {
          id: "#{tag_id}_editor", role: "textbox", "aria-multiline": "true",
          "aria-labelledby": ("#{tag_id}_label" unless label == false), "aria-describedby": aria_described_by,
          "aria-invalid": aria_invalid, "aria-required": ("true" if required),
          class: helpers.class_names("rich-text-area-content min-h-32 px-3 py-2 text-base text-gray-900 focus:outline-none sm:text-sm/6 auto-dark:text-white", html_options[:class])
        }.compact
      end

      def controller_data
        {
          controller: "form-components--rich-text-area",
          "form-components--rich-text-area-toolbar-value": toolbar.without(:|).to_json,
          "form-components--rich-text-area-attributes-value": editor_attributes.to_json,
          "form-components--rich-text-area-placeholder-value": placeholder,
          "form-components--rich-text-area-action-text-value": action_text?.to_s,
          "form-components--rich-text-area-direct-upload-url-value": (direct_upload_url if uploads?),
          "form-components--rich-text-area-blob-url-template-value": (blob_url_template if uploads?),
          "form-components--rich-text-area-disabled-value": html_options[:disabled].present?.to_s,
          action: "click@document->form-components--rich-text-area#clickOutside"
        }.compact
      end

      def wrapper_classes
        class_names("relative mt-2 rounded-md bg-white outline outline-1 -outline-offset-1 focus-within:outline-2 focus-within:-outline-offset-1 auto-dark:bg-white/5",
          {"outline-gray-300 focus-within:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 focus-within:outline-red-600 auto-dark:outline-red-500/50" => has_error?})
      end

      def button_classes
        "flex size-7 items-center justify-center rounded-md text-sm text-gray-600 hover:bg-gray-100 hover:text-gray-900 disabled:cursor-not-allowed disabled:opacity-40 aria-pressed:bg-primary-50 aria-pressed:text-primary-700 auto-dark:text-gray-300 auto-dark:hover:bg-white/10 auto-dark:hover:text-white auto-dark:aria-pressed:bg-white/15 auto-dark:aria-pressed:text-white"
      end

      private

      def raw_value
        object&.public_send(method) if object.respond_to?(method)
      end

      def data_option(name)
        data = (html_options[:data] || {}).symbolize_keys
        data.key?(name) ? data[name] : yield
      end

      def blob_url(blob)
        blob_url_template.to_s.sub(":signed_id", blob.signed_id).sub(":filename", ERB::Util.url_encode(blob.filename.to_s))
      end

      def main_app = helpers.main_app
    end
  end
end
