module FormComponents
  module ErrorSummary
    # The form's errors, listed above its fields, each a link to its field,
    # as the W3C's forms tutorial has it: shown when there are errors, and
    # focused (autofocus), so a screen reader reads it as the page shows after
    # a form that didn't save. A region, named by its heading, to go back to.
    #
    #   <%= f.error_summary %>
    #
    # title: its heading, else "There are 2 errors in this form"
    class Component < FormComponents::Base::Component
      self.extras = %i[title]

      CLASSES = "form-error-summary rounded-md bg-red-50 p-4 focus:outline-2 focus:outline-offset-2 focus:outline-red-600 auto-dark:bg-red-500/15 auto-dark:outline-red-500/50"

      option_reader :title

      # As FormBuilder#error_summary(options = {})
      def initialize(form, object, options = {})
        super(form, object, nil, options)
      end

      def render?
        object.respond_to?(:errors) && object.errors.any?
      end

      def heading
        title.presence || I18n.t("form_components.error_summary.title", count: object.errors.count,
          default: {one: "There is 1 error in this form", other: "There are %{count} errors in this form"})
      end

      def heading_id = "#{form.field_id(:error_summary)}_title"

      # Each error's message and its field's id, none for the record's own
      # (base) or a nested record's
      def errors
        object.errors.map { |error| [error.full_message, field_id(error.attribute)] }
      end

      def summary_attributes
        html_options.merge(class: class_names(CLASSES, html_options[:class]), role: "region", tabindex: -1, autofocus: true, "aria-labelledby": heading_id)
      end

      private

      # A belongs_to's errors are its foreign key's field's
      def field_id(attribute)
        return if attribute == :base || attribute.to_s.include?(".")

        reflection = object.class.reflect_on_association(attribute) if object.class.respond_to?(:reflect_on_association)
        form.field_id(reflection&.belongs_to? ? reflection.foreign_key : attribute, index: form.options[:index])
      end
    end
  end
end
