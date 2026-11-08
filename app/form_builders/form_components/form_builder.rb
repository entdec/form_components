# frozen_string_literal: true

module FormComponents
  # Form builder that uses components
  # We define a DSL and a validation context
  #
  #   = form_with model: @post, builder: FormComponents::FormBuilder do |f|
  #     = f.text_field :title
  class FormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::TagHelper
    include FormComponents::ValidationContext
    include FormComponents::Dsl

    # label(method, text = nil, options = {}, &block)
    form_component :label

    # text_field(method, options = {})
    form_component :text_field

    # check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    form_component :check_box
    alias_method :checkbox, :check_box

    # collection_check_boxes(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
    form_component :collection_check_boxes
    alias_method :collection_checkboxes, :collection_check_boxes

    # radio_button(method, tag_value, options = {})
    form_component :radio_button
    alias_method :radiobutton, :radio_button

    # collection_radio_buttons(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
    form_component :collection_radio_buttons
    alias_method :collection_radiobuttons, :collection_radio_buttons

    # submit(value = nil, options = {})
    form_component :submit

    form_component :text_area
    alias_method :textarea, :text_area

    # color_field(method, options = {}), with swatches: ["#rrggbb", ...] to pick from
    form_component :color_field

    # file_field(method, options = {}), with preview: an attachment to show above the field
    def file_field(method, options = {})
      self.multipart = true
      render_component(:file_field, @object, method, options)
    end

    text_field_form_component :password
    text_field_form_component :search
    text_field_form_component :date
    text_field_form_component :time
    text_field_form_component :datetime
    text_field_form_component :datetime_local
    text_field_form_component :month
    text_field_form_component :week
    text_field_form_component :url
    text_field_form_component :email
    text_field_form_component :number

    # Renders a Stimulus-driven nested form for a has_many association.
    # The block receives the component (nf) so you can declare slots:
    #
    #   = f.nested_form :sections do |nf|
    #     - nf.with_item do |sf|
    #       .section-wrapper data-new-record=sf.object.new_record?.to_s
    #         = sf.hidden_field :_destroy
    #         = sf.text_field :title
    #     - nf.with_add_button
    #       button type="button" data-action="form-components--nested-form#add" Add section
    #
    # Options (keyword arguments):
    #   placeholder:      – Stimulus token replaced on clone, default "NEW_<SINGULAR>"
    #   wrapper_selector: – CSS selector for the remove handler, default ".<singular>-wrapper"
    #   new_record:       – template record object, default association_class.new
    #   add_label:        – label for the default add button
    def nested_form(method, **options, &block)
      FormComponents::NestedForm::Component.new(self, @object, method, options).render_in(@template, &block)
    end
  end
end
