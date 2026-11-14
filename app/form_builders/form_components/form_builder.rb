# frozen_string_literal: true

module FormComponents
  # A form builder whose fields are components. Each helper takes the
  # arguments Rails' takes, and its input is Rails' own (see
  # Base::Component#rails), so names, ids, values and options are Rails'; the
  # components add a label, a description, errors and the like around it,
  # with options of their own (label:, description:, …) that Rails doesn't
  # get. Helpers without a component here, such as hidden_field or date_select,
  # are Rails'.
  #
  #   = form_with model: @post, builder: FormComponents::FormBuilder do |f|
  #     = f.text_field :title
  class FormBuilder < ActionView::Helpers::FormBuilder
    include FormComponents::ValidationContext

    # Rails' text fields of every kind, as TextField
    TEXT_FIELDS = %i[text_field password_field search_field telephone_field phone_field date_field time_field
      datetime_field datetime_local_field month_field week_field url_field email_field number_field].freeze

    def label(method, text = nil, options = {}, &block)
      component(:label, method, text, options, &block)
    end

    TEXT_FIELDS.each do |helper|
      define_method(helper) do |method, options = {}|
        component(:text_field, method, options, helper: helper)
      end
    end

    def text_area(method, options = {})
      component(:text_area, method, options)
    end
    alias_method :textarea, :text_area

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      component(:check_box, method, options, checked_value, unchecked_value)
    end
    alias_method :checkbox, :check_box

    def radio_button(method, tag_value, options = {})
      component(:radio_button, method, tag_value, options)
    end
    alias_method :radiobutton, :radio_button

    def collection_check_boxes(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
      component(:collection_check_boxes, method, collection, value_method, text_method, options, html_options, &block)
    end
    alias_method :collection_checkboxes, :collection_check_boxes

    def collection_radio_buttons(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
      component(:collection_radio_buttons, method, collection, value_method, text_method, options, html_options, &block)
    end
    alias_method :collection_radiobuttons, :collection_radio_buttons

    def select(method, choices = nil, options = {}, html_options = {}, &block)
      component(:select, method, [choices], options, html_options, &block)
    end

    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      component(:select, method, [collection, value_method, text_method], options, html_options, helper: :collection_select)
    end

    def grouped_collection_select(method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
      component(:select, method, [collection, group_method, group_label_method, option_key_method, option_value_method], options, html_options, helper: :grouped_collection_select)
    end

    def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
      component(:select, method, [priority_zones], options, html_options, helper: :time_zone_select)
    end

    def weekday_select(method, options = {}, html_options = {})
      component(:select, method, [], options, html_options, helper: :weekday_select)
    end

    # hotwire_combobox's combobox, when the host has that gem
    def combobox(method, options_or_src = [], **options, &block)
      component(:combobox, method, options_or_src, options, &block)
    end

    # Stars to rate with, from 1 to max: (5)
    def rating_field(method, options = {})
      component(:rating_field, method, options)
    end

    # A number to pick on a scale, in: (1..5), with min_label: and max_label:
    # at its ends
    def scale_field(method, options = {})
      component(:scale_field, method, options)
    end

    # A text field for a color picker, see ColorField: with swatches: to pick
    # from, and default: shown while it's empty
    def color_field(method, options = {})
      component(:color_field, method, options)
    end

    # With preview: an attachment to show above the field
    def file_field(method, options = {})
      component(:file_field, method, options)
    end

    def submit(value = nil, options = {})
      FormComponents::Submit::Component.new(self, @object, value, options).render_in(@template)
    end

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

    private

    def component(name, method, *, **, &block)
      FormComponents.const_get("#{name.to_s.camelize}::Component").new(self, @object, method, *, **, &block).render_in(@template)
    end
  end
end
