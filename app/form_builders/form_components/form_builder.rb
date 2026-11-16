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
  #   <%= form_with model: @post, builder: FormComponents::FormBuilder do |f| %>
  #     <%= f.text_field :title %>
  #   <% end %>
  class FormBuilder < ActionView::Helpers::FormBuilder
    include FormComponents::ValidationContext

    # Adds a helper to the builder for one of the app's components: the block
    # gets the helper's arguments and returns the component, run in the
    # builder (self, object, @template), and the helper renders it, with the
    # helper's own block as its content. Again for the same name replaces it,
    # so it can be done in a to_prepare, for components that reload:
    #
    #   FormComponents::FormBuilder.register(:image_upload) do |method = :photo, **options|
    #     ImageUpload::Component.new(form: self, attribute: method, **options)
    #   end
    #
    #   <%= f.image_upload :logo, shape: :square %>
    def self.register(name, &build)
      raise ArgumentError, "register :#{name} needs a block that returns the component" unless build

      define_method(name) do |*args, **options, &content|
        instance_exec(*args, **options, &build).render_in(@template, &content)
      end
    end

    # Rails' text fields of every kind, as TextField
    TEXT_FIELDS = %i[text_field password_field search_field date_field time_field
      datetime_field datetime_local_field month_field week_field url_field email_field number_field].freeze

    def label(method, text = nil, options = {}, &block)
      component(:label, method, text, options, &block)
    end

    TEXT_FIELDS.each do |helper|
      define_method(helper) do |method, options = {}|
        component(:text_field, method, options, helper: helper)
      end
    end

    # Rails' arguments, with a country picker: the number is sent with its
    # country's calling code, see TelephoneField
    def telephone_field(method, options = {})
      component(:telephone_field, method, options)
    end
    alias_method :phone_field, :telephone_field

    def text_area(method, options = {})
      component(:text_area, method, options)
    end
    alias_method :textarea, :text_area

    # A Tiptap editor instead of Rails' Trix, for an Action Text attribute or
    # one with HTML, see RichTextArea: with toolbar: its buttons
    def rich_text_area(method, options = {})
      component(:rich_text_area, method, options)
    end
    alias_method :rich_textarea, :rich_text_area

    # A CodeMirror editor for code (SQL, JSON, YAML, Liquid, …), see
    # CodeEditor: lang: its language, height: its height
    def code_editor(method, options = {})
      component(:code_editor, method, options)
    end
    alias_method :editor, :code_editor

    # A signature drawn on a pad, sent as an SVG file for an Active Storage
    # attachment, see SignatureField: width: and height: the pad's
    def signature_field(method, options = {})
      component(:signature_field, method, options)
    end
    alias_method :signature, :signature_field

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

    # A group of fields in a card, see Fieldset: as Rails' field_set_tag,
    # with description: and legend_position: (:above, :inside, :beside)
    def fieldset(legend = nil, options = {}, &block)
      FormComponents::Fieldset::Component.new(legend, options).render_in(@template, &block)
    end
    alias_method :field_set, :fieldset

    def submit(value = nil, options = {})
      FormComponents::Submit::Component.new(self, @object, value, options).render_in(@template)
    end

    # Renders a Stimulus-driven nested form for a has_many association.
    # The block receives the component (nf) so you can declare slots:
    #
    #   <%= f.nested_form :sections do |nf| %>
    #     <% nf.with_item do |sf| %>
    #       <div class="section-wrapper" data-new-record="<%= sf.object.new_record? %>">
    #         <%= sf.hidden_field :_destroy %>
    #         <%= sf.text_field :title %>
    #       </div>
    #     <% end %>
    #     <% nf.with_add_button do %>
    #       <button type="button" data-action="form-components--nested-form#add">Add section</button>
    #     <% end %>
    #   <% end %>
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
