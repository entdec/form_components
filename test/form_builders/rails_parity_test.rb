# frozen_string_literal: true

require "test_helper"

# Each helper gives the form controls Rails' own builder gives for the same
# arguments: the same elements, names, ids, values, types and options. Only
# classes and the aria attributes we add may differ, and our extras (a label,
# a description, …) are around them.
class RailsParityTest < ComponentTest
  EXTRAS = {label: "A label", description: "A description"}.freeze

  # The inputs, text areas and buttons of some HTML, with their attributes
  # but class and aria-invalid/aria-describedby, and a text area's text
  def controls(html)
    Nokogiri::HTML5.fragment(html.to_s).css("input, textarea, select, button").map do |node|
      attributes = node.attributes.transform_values(&:value).except("class", "aria-invalid", "aria-describedby")
      [node.name, attributes, (node.text if node.name == "textarea")]
    end
  end

  def assert_parity(helper, *args, post: Post.new, form_options: {}, extras: {}, &block)
    ours = form(post, **form_options).public_send(helper, *ours_args(args, extras), &block)
    rails = rails_form(post, **form_options).public_send(helper, *args, &block)

    assert_not_empty controls(rails), "Rails renders no controls for #{helper}"
    assert_equal controls(rails), controls(ours), "#{helper}(#{args.map(&:inspect).join(", ")})"
  end

  # Our extras go in the options, which is the last hash Rails takes; they
  # mustn't reach Rails
  def ours_args(args, extras)
    return args if extras.empty?

    index = args.rindex { |arg| arg.is_a?(Hash) }
    return args + [extras] if index.nil?

    args.dup.tap { |copy| copy[index] = copy[index].merge(extras) }
  end

  FormComponents::FormBuilder::TEXT_FIELDS.each do |helper|
    test "#{helper} as Rails'" do
      post = Post.new(title: "Hello & <b>bye</b>", starts_on: Date.new(2026, 11, 14), starts_at: Time.utc(2026, 11, 14, 9, 30), count: 3)
      attribute = case helper
      when :date_field, :month_field, :week_field then :starts_on
      when :datetime_field, :datetime_local_field, :time_field then :starts_at
      when :number_field then :count
      else :title
      end

      assert_parity helper, attribute, post: post
      assert_parity helper, attribute, {}, post: post, extras: EXTRAS.merge(leading_icon: "fas fa-x", corner_hint: "Optional")
      assert_parity helper, attribute, {placeholder: "x", class: "mine", data: {a: 1}, maxlength: 5, required: true, autofocus: true, disabled: true}, post: post
      assert_parity helper, attribute, {value: "given", id: "custom", name: "other[name]"}, post: post
      assert_parity helper, attribute, {index: 3}, post: post
      assert_parity helper, attribute, {aria: {label: "Given"}, "aria-describedby": "elsewhere"}, post: post
      assert_parity helper, attribute, post: post, form_options: {namespace: "ns", index: 2}
      assert_parity helper, attribute, post: nil
    end
  end

  test "number_field with a range and a step, date_field with bounds, as Rails'" do
    assert_parity :number_field, :count, {in: 1..10, step: 2}
    assert_parity :date_field, :starts_on, {min: Date.new(2026, 1, 1), max: Date.new(2026, 12, 31)}
  end

  test "password_field leaves out the value unless given, as Rails" do
    post = Post.new(password: "secret")
    assert_parity :password_field, :password, post: post
    assert_parity :password_field, :password, {value: "given"}, post: post
  end

  test "text_area as Rails'" do
    post = Post.new(body: "Hello\n<b>there</b>")
    assert_parity :text_area, :body, post: post
    assert_parity :text_area, :body, {}, post: post, extras: EXTRAS.merge(corner_hint: "Optional")
    assert_parity :text_area, :body, {size: "20x5", placeholder: "x", class: "mine", value: "given"}, post: post
    assert_parity :textarea, :body, post: post
  end

  test "check_box as Rails', with its hidden field" do
    assert_parity :check_box, :published, post: Post.new(published: true)
    assert_parity :check_box, :published, {}, post: Post.new(published: true), extras: EXTRAS
    assert_parity :check_box, :published, {}, "yes", "no", post: Post.new(published: false)
    assert_parity :check_box, :published, {include_hidden: false, class: "mine", disabled: true}
    assert_parity :check_box, :published, {checked: true}
    assert_parity :check_box, :tags, {multiple: true}, "ruby", nil, post: Post.new(tags: ["ruby"])
    assert_parity :check_box, :tags, {multiple: true}, "Some Value", nil
    assert_parity :checkbox, :published
  end

  test "radio_button as Rails'" do
    post = Post.new(kind: "news")
    assert_parity :radio_button, :kind, "news", post: post
    assert_parity :radio_button, :kind, "news", {}, post: post, extras: EXTRAS
    assert_parity :radio_button, :kind, "Some Value.1", post: post
    assert_parity :radio_button, :kind, "blog", {checked: true, class: "mine", id: "custom"}, post: post
    assert_parity :radio_button, :kind, :news, post: post
  end

  test "collection_check_boxes as Rails', with its hidden field" do
    post = Post.new(tags: ["rails"])
    assert_parity :collection_check_boxes, :tags, Post::TAGS, :itself, :titleize, post: post
    assert_parity :collection_check_boxes, :tags, Post::TAGS, :itself, :titleize, {}, post: post, extras: EXTRAS.merge(description_method: :upcase)
    assert_parity :collection_check_boxes, :tags, Post::TAGS, :itself, :titleize, {include_hidden: false, checked: ["ruby"], disabled: ["tailwind"]}, {class: "mine", data: {a: 1}}, post: post
    assert_parity :collection_check_boxes, :tags, Post::TAGS, ->(tag) { tag.upcase }, ->(tag) { "Tag #{tag}" }, post: post
    assert_parity :collection_checkboxes, :tags, Post::TAGS, :itself, :titleize, post: post
  end

  test "collection_check_boxes with a block renders its items as Rails does" do
    assert_parity(:collection_check_boxes, :tags, Post::TAGS, :itself, :titleize) { |b| b.label { b.check_box + b.text } }
  end

  test "collection_radio_buttons as Rails'" do
    post = Post.new(kind: "blog")
    assert_parity :collection_radio_buttons, :kind, Post::KINDS, :first, :second, post: post
    assert_parity :collection_radio_buttons, :kind, Post::KINDS, :first, :second, {}, post: post, extras: EXTRAS.merge(description_method: :third)
    assert_parity :collection_radio_buttons, :kind, Post::KINDS, :first, :second, {include_hidden: false, checked: "news", disabled: "blog"}, {class: "mine"}, post: post
    assert_parity(:collection_radio_buttons, :kind, Post::KINDS, :first, :second, post: post) { |b| b.radio_button + b.label }
  end

  test "select as Rails'" do
    post = Post.new(category: "Review")
    assert_parity :select, :category, ["News", "Review"], post: post
    assert_parity :select, :category, ["News", "Review"], {}, post: post, extras: EXTRAS
    assert_parity :select, :category, [["News", "news"], ["Review", "review"]], {include_blank: "None", selected: "review", disabled: "news"}, {class: "mine", data: {a: 1}, required: true}, post: post
    assert_parity :select, :category, ["News", "Review"], {prompt: true}, {id: "custom", name: "other"}, post: post
    assert_parity :select, :tags, Post::TAGS, {}, {multiple: true}, post: Post.new(tags: ["ruby"])
    assert_parity :select, :tags, Post::TAGS, {include_hidden: false}, {multiple: true}
    assert_parity :select, :category, ["News"], {index: 3}
    assert_parity :select, :category, ["News"], post: post, form_options: {namespace: "ns", index: 2}
  end

  test "select with a block as Rails'" do
    assert_parity(:select, :category) { "<option value=\"x\">X</option>".html_safe }
  end

  test "collection_select, grouped_collection_select, time_zone_select and weekday_select as Rails'" do
    post = Post.new(language: "nl", time_zone: "Amsterdam")
    groups = [Struct.new(:name, :languages).new("Europe", Post::LANGUAGES)]

    assert_parity :collection_select, :language, Post::LANGUAGES, :first, :second, post: post
    assert_parity :collection_select, :language, Post::LANGUAGES, :first, :second, {include_blank: true}, {class: "mine"}, post: post, extras: EXTRAS
    assert_parity :grouped_collection_select, :language, groups, :languages, :name, :first, :second, post: post
    assert_parity :grouped_collection_select, :language, groups, :languages, :name, :first, :second, {prompt: true}, {}, post: post, extras: EXTRAS
    assert_parity :time_zone_select, :time_zone, post: post
    assert_parity :time_zone_select, :time_zone, ActiveSupport::TimeZone.us_zones, {include_blank: true}, {class: "mine"}, post: post, extras: EXTRAS
    assert_parity :weekday_select, :category
    assert_parity :weekday_select, :category, {index_as_value: true}, {}, extras: EXTRAS
  end

  test "combobox as hotwire_combobox's" do
    post = Post.new(city: "Utrecht")
    combobox = ->(builder, *args, **options) { builder.combobox(:city, *args, **options) }

    [[[Post::CITIES], {}], [[Post::CITIES], {placeholder: "A city", id: "custom", free_text: true}], [["/cities"], {}]].each do |args, options|
      ours = controls(combobox.call(form(post), *args, **options, **EXTRAS))
      theirs = controls(combobox.call(rails_form(post), *args, **options))
      assert_not_empty theirs
      assert_equal theirs, ours, "combobox(#{args.inspect}, #{options.inspect})"
    end
  end

  test "file_field as Rails'" do
    assert_parity :file_field, :logo
    assert_parity :file_field, :logo, {}, extras: EXTRAS.merge(preview: nil)
    assert_parity :file_field, :logo, {multiple: true, accept: "image/*", class: "mine"}
    assert_parity :file_field, :logo, {multiple: true, include_hidden: false}
  end

  test "submit as Rails'" do
    assert_parity :submit
    assert_parity :submit, "Save"
    assert_parity :submit, {class: "mine", data: {disable_with: false}}
    assert_parity :submit, "Save", {name: "continue", id: "go"}
    assert_parity :submit, post: nil
  end

  test "color_field: Rails' name, id and options, in a text field that can be empty" do
    ours = controls(form(Post.new).color_field(:color, swatches: ["#e6007e"], default: "#e6007e", maxlength: 7, data: {a: 1}))
    rails = controls(rails_form(Post.new).color_field(:color, maxlength: 7, data: {a: 1}))

    assert_equal rails.first[1].except("type", "value"), ours.first[1].except("type", "value", "placeholder", "data-form-components--color-field-target")
    assert_equal ["text", nil], ours.first[1].values_at("type", "value")
    assert_equal "#000000", rails.first[1]["value"]
  end

  test "fields_for gives nested fields Rails' names and ids" do
    post = Post.new(sections: [Section.new(title: "Intro")])
    ours = form(post).fields_for(:sections) { |sf| sf.text_field(:title) + sf.check_box(:title) }
    rails = rails_form(post).fields_for(:sections) { |sf| sf.text_field(:title) + sf.check_box(:title) }

    assert_equal controls(rails), controls(ours)
  end

  test "fields with errors are Rails', wrapped as Rails wraps them" do
    post = Post.new
    post.validate
    ours = form(post).text_field(:title)

    assert_equal controls(rails_form(post).text_field(:title)), controls(ours)
    assert_includes ours, "field_with_errors"
  end
end
