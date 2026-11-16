# frozen_string_literal: true

require "test_helper"

class TextFieldTest < ComponentTest
  test "a labelled input with the record's value" do
    post = Post.new(title: "Hello")
    render_inline FormComponents::TextField::Component.new(form(post), post, :title, placeholder: "A title", description: "Shown on top")

    assert_select "label[for=post_title]", text: "Title"
    assert_select "input[name='post[title]'][value=Hello][placeholder='A title'][aria-invalid=false][aria-describedby=post_title_description]"
    assert_select "p#post_title_description", text: "Shown on top"
  end

  test "marks a required attribute and shows its errors" do
    post = Post.new
    post.validate
    render_inline FormComponents::TextField::Component.new(form(post), post, :title)

    assert_select "label[for=post_title] .fa-asterisk"
    assert_select "input[required][aria-invalid=true][aria-describedby=post_title_error]"
    assert_select "p#post_title_error", text: "can't be blank"
  end

  test "without a label" do
    render_inline FormComponents::TextField::Component.new(form, Post.new, :title, label: false)

    assert_select "label", count: 0
  end
end

class ColorFieldTest < ComponentTest
  test "renders a text input for the picker" do
    post = Post.new(color: "#1e40af")
    render_inline FormComponents::ColorField::Component.new(form(post), post, :color, swatches: ["#e6007e", "#1e40af"])

    assert_select "label[for='post_color']", text: "Color"
    assert_select ".form-color-field[data-controller='form-components--color-field'][data-form-components--color-field-swatches-value='[\"#e6007e\",\"#1e40af\"]'] input[type=text][name='post[color]'][value='#1e40af'][data-form-components--color-field-target='input']"
  end

  test "shows the default color while it's empty" do
    render_inline FormComponents::ColorField::Component.new(form, Post.new, :color, default: "#e6007e", placeholder: "Brand color")

    assert_select ".form-color-field--default[style='--color-field-default: #e6007e'] input[placeholder='#e6007e']"
  end

  test "shows the placeholder without a default color" do
    [nil, "red; background: url(x)"].each do |default|
      render_inline FormComponents::ColorField::Component.new(form, Post.new, :color, default: default, placeholder: "Brand color")

      assert_select ".form-color-field:not(.form-color-field--default):not([style]) input[placeholder='Brand color']"
    end
  end

  test "shows the description and errors" do
    post = Post.new(color: "red")
    post.validate
    render_inline FormComponents::ColorField::Component.new(form(post), post, :color, description: "For the bar")

    assert_select "p#post_color_description", text: "For the bar"
    assert_select ".form-color-field--error input[aria-invalid='true'][aria-describedby='post_color_error post_color_description']"
    assert_select "p#post_color_error", text: "is invalid"
  end
end

class FileFieldTest < ComponentTest
  # An attachment, as far as the file field looks at it
  Attachment = Struct.new(:stored) do
    def attached? = true

    def blob = Struct.new(:persisted?).new(stored)

    def representable? = true

    def representation(**) = "/logo.png"
  end

  test "renders a file input" do
    render_inline FormComponents::FileField::Component.new(form, Post.new, :body, accept: "image/*", description: "A logo")

    assert_select "label[for='post_body']", text: "Body"
    assert_select "input[type=file][name='post[body]'][accept='image/*'][aria-describedby='post_body_description']"
    assert_select "p#post_body_description", text: "A logo"
    assert_select "img", count: 0
  end

  test "shows the attached image" do
    render_inline FormComponents::FileField::Component.new(form, Post.new, :body, preview: Attachment.new(true))

    assert_select "img[src='/logo.png']"
  end

  test "doesn't show an image that isn't stored yet" do
    # As after a form with a new upload didn't save
    render_inline FormComponents::FileField::Component.new(form, Post.new, :body, preview: Attachment.new(false))

    assert_select "img", count: 0
  end
end

class CheckBoxTest < ComponentTest
  test "a check box with a hidden unchecked value" do
    post = Post.new(published: true)
    render_inline FormComponents::CheckBox::Component.new(form(post), post, :published)

    assert_select "input[type=hidden][name='post[published]'][value='0']"
    assert_select "input[type=checkbox][name='post[published]'][value='1'][checked]"
    assert_select "label[for=post_published]", text: "Published"
  end

  test "as a switch: the same check box, a switch to assistive technology, over its track" do
    post = Post.new(published: true)
    html = Nokogiri::HTML5.fragment(form(post).check_box(:published, switch: true, description: "On the site"))

    assert html.at_css("input[type=hidden][name='post[published]'][value='0']")
    track = html.at_css(".group.rounded-full.has-checked\\:bg-primary-600")
    assert track.at_css("input[type=checkbox][role=switch][name='post[published]'][value='1'][checked].appearance-none")
    assert track.at_css("span.group-has-checked\\:translate-x-5")
    assert html.at_css("label[for=post_published]", text: "Published")
    assert_nil html.at_css("input[switch]")
  end
end

class RadioButtonTest < ComponentTest
  test "a radio button per item" do
    post = Post.new(kind: "news")
    kinds = [Struct.new(:id, :name).new("news", "News"), Struct.new(:id, :name).new("blog", "Blog")]
    render_inline FormComponents::CollectionRadioButtons::Component.new(form(post), post, :kind, kinds, :id, :name)

    assert_select "input[type=radio][name='post[kind]']", count: 2
    assert_select "input#post_kind_news[value=news][checked]"
    assert_select "input#post_kind_blog[value=blog]:not([checked])"
  end

  test "checks a symbol value, and not one the attribute merely contains" do
    post = Post.new(kind: "draft")
    render_inline FormComponents::CollectionRadioButtons::Component.new(form(post), post, :kind, [["Draft", :draft], ["Raft", :raft]], :last, :first)

    assert_select "input#post_kind_draft[checked]"
    assert_select "input#post_kind_raft:not([checked])"
  end
end

class SubmitTest < ComponentTest
  test "named after the record" do
    render_inline FormComponents::Submit::Component.new(form, Post.new, nil)

    assert_select "input[type=submit][value='Create Post']"
  end
end

class NestedFormTest < ComponentTest
  test "the items, and a template to add one from" do
    post = Post.new(sections: [Section.new(title: "Intro")])
    render_inline(FormComponents::NestedForm::Component.new(form(post), post, :sections, {new_record: Section.new})) do |nf|
      nf.with_item { |sf| sf.text_field(:title) }
    end

    assert_select "[data-controller='form-components--nested-form'][data-form-components--nested-form-placeholder-value=NEW_SECTION][data-form-components--nested-form-wrapper-selector-value='.section-wrapper']"
    assert_select "template[data-form-components--nested-form-target=template]"
    assert_select "input[name='post[sections_attributes][0][title]'][value=Intro]"
    assert_select "[data-action='click->form-components--nested-form#add'] button", text: /Add section/
  end
end

class FieldsetTest < ComponentTest
  test "its fields in a card, under a heading that is its legend, with a description" do
    render_inline(FormComponents::Fieldset::Component.new("Pricing", description: "What it costs", id: "pricing", class: "mine")) { "<input name=price>".html_safe }

    assert_select "fieldset#pricing.form-fieldset.form-fieldset--above.relative.mine[aria-describedby=pricing_description]"
    assert_select "fieldset > legend.sr-only", text: "Pricing"
    assert_select ".form-fieldset__heading [aria-hidden=true]", text: "Pricing"
    assert_select "p#pricing_description", text: "What it costs"
    assert_select ".form-fieldset__body.rounded-xl input[name=price]"
  end

  test "the heading inside the card, or beside it" do
    render_inline(FormComponents::Fieldset::Component.new("Status", legend_position: :inside)) { "x" }
    assert_select "fieldset.form-fieldset--inside.rounded-xl .form-fieldset__heading"
    assert_select ".form-fieldset__body.rounded-xl", count: 0

    render_inline(FormComponents::Fieldset::Component.new("Profile", legend_position: "beside")) { "x" }
    assert_select "fieldset.form-fieldset--beside.md\\:grid-cols-3"
    assert_select ".form-fieldset__body.rounded-xl.md\\:col-span-2"
  end

  test "without a heading, only the card" do
    render_inline(FormComponents::Fieldset::Component.new) { "x" }

    assert_select "fieldset:not([aria-describedby]) .form-fieldset__body", text: "x"
    assert_select "legend, .form-fieldset__heading", count: 0
  end

  test "no other position" do
    assert_raises(ArgumentError) { FormComponents::Fieldset::Component.new("A", legend_position: :below) }
  end

  test "from the form, around its fields" do
    view = vc_test_controller.view_context
    f = FormComponents::FormBuilder.new(:post, Post.new, view, {})
    @rendered_content = f.fieldset("About", legend_position: :inside) { f.text_field(:title) }

    assert_select "fieldset.form-fieldset--inside legend", text: "About"
    assert_select "fieldset .form-fieldset__body input[name='post[title]']"
  end

  def rendered_content = @rendered_content || super
end
