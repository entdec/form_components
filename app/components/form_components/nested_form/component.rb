# frozen_string_literal: true

module FormComponents
  module NestedForm
    # ViewComponent that encapsulates the Stimulus-driven nested-form pattern.
    #
    # Usage (in a Slim template with a FormComponents::FormBuilder):
    #
    #   = f.nested_form :sections do |nf|
    #     - nf.with_item do |sf|
    #       .section-wrapper data-new-record=sf.object.new_record?.to_s
    #         = sf.hidden_field :_destroy
    #         = sf.text_field :title
    #     - nf.with_add_button
    #       button type="button" data-action="form-components--nested-form#add" Add section
    #
    # The same +with_item+ block is used for both:
    #   • the hidden HTML <template> tag (rendered with a new record so that
    #     Stimulus can clone it when the user clicks "Add"), and
    #   • each existing / in-memory record returned by fields_for.
    #
    # Options (passed as keyword arguments to f.nested_form):
    #   :placeholder      – Stimulus placeholder string, default "NEW_<SINGULAR>"
    #   :wrapper_selector – CSS selector the remove handler uses to find the
    #                       wrapping element, default ".<singular>-wrapper"
    #   :new_record       – object used as the template record (default: association klass.new)
    #   :add_label        – fallback label for the auto-generated add button
    class Component < FormComponents::Base::Component
      renders_one :add_button

      attr_reader :item_block

      def with_item(&block)
        @item_block = block
        self
      end

      # Execute the outer (slot-collecting) block so that with_item and
      # with_add_button are called and their content registered before
      # ViewComponent renders the template.
      def render_in(view_context, &block)
        block.call(self) if block_given?
        super(view_context)
      end

      # Stimulus placeholder token, e.g. "NEW_SECTION" for :sections.
      def placeholder
        options.fetch(:placeholder) { "NEW_#{method.to_s.singularize.upcase}" }
      end

      # CSS selector used by the Stimulus remove action to locate the wrapper
      # element, e.g. ".section-wrapper" for :sections.
      def wrapper_selector
        options.fetch(:wrapper_selector) { ".#{method.to_s.singularize}-wrapper" }
      end

      # Label for the fallback add button when no with_add_button slot is given.
      def add_label
        options.fetch(:add_label) { "Add #{method.to_s.singularize.humanize.downcase}" }
      end

      # An unsaved instance of the associated model used as the record inside
      # the HTML <template> tag so Stimulus can clone it on "Add".
      def new_record_object
        options.fetch(:new_record) do
          object.class.reflect_on_association(method)&.klass&.new
        end
      end
    end
  end
end
