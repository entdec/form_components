module FormComponents
  module CodeEditor
    # A CodeMirror editor (vendor/javascript/form_components/codemirror.js)
    # for code: SQL, JSON, YAML, Liquid and the like, as Satis' editor.
    #
    # The code is in Rails' text_area, with its name, id and options, out of
    # sight, as the rich text area's: the controller keeps it up to date, the
    # label points at it and the browser checks it when it's required, and it
    # hands its focus to the editor. So it needs JS. readonly: or disabled:
    # makes the editor read-only.
    #
    # lang: the language (LANGUAGES), none for plain text; height: the
    # editor's height (CSS), it scrolls beyond it.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[corner_hint lang height]

      LANGUAGES = %w[sql json yaml liquid markdown javascript html css].freeze

      # The height of every code editor, unless height: is given
      class_attribute :default_height, default: "12rem"

      # Next to the label, above the field
      option_reader :corner_hint

      def lang
        lang = options[:lang]&.to_s
        raise ArgumentError, "Unknown code editor language: #{lang}, one of #{LANGUAGES.join(", ")}" if lang && !LANGUAGES.include?(lang)

        lang
      end

      def height = options.fetch(:height, default_height)

      # Rails' text area, with the code, out of sight
      def input
        given = input_options("pointer-events-none absolute bottom-0 left-1/2 size-px resize-none opacity-0", from: html_options.except(:class))
        data = (html_options[:data] || {}).symbolize_keys
        rails(:text_area, method, given.except(:"aria-invalid", :"aria-describedby").merge(tabindex: -1, "aria-hidden": "true",
          data: data.merge("form-components--code-editor-target": "input", action: "focus->form-components--code-editor#focus invalid->form-components--code-editor#focus")))
      end

      def field_label(id = tag_id, value: nil)
        return if label == false

        form.label(method, label.presence, for: id, id: "#{id}_label")
      end

      # The editor's own attributes, for the controller to give its content
      def editor_attributes
        required = html_options.key?(:required) ? html_options[:required] : required_attribute?
        {
          id: "#{tag_id}_editor", "aria-labelledby": ("#{tag_id}_label" unless label == false), "aria-describedby": aria_described_by,
          "aria-invalid": aria_invalid, "aria-required": ("true" if required)
        }.compact
      end

      def read_only?
        html_options[:readonly].present? || html_options[:disabled].present?
      end

      def controller_data
        {
          controller: "form-components--code-editor",
          "form-components--code-editor-lang-value": lang,
          "form-components--code-editor-height-value": height,
          "form-components--code-editor-read-only-value": read_only?.to_s,
          "form-components--code-editor-attributes-value": editor_attributes.to_json
        }.compact
      end

      def wrapper_classes
        class_names("form-code-editor relative mt-2 overflow-hidden rounded-md bg-white outline outline-1 -outline-offset-1 focus-within:outline-2 focus-within:-outline-offset-1 auto-dark:bg-white/5",
          {"outline-gray-300 focus-within:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 focus-within:outline-red-600 auto-dark:outline-red-500/50" => has_error?},
          html_options[:class])
      end
    end
  end
end
