# frozen_string_literal: true

require "test_helper"

# What the components add to Rails' fields
class LabelTest < ComponentTest
  test "Rails' label, marked when required" do
    render_inline FormComponents::Label::Component.new(form, Post.new, :title)

    assert_select "label[for=post_title]", text: "Title"
    assert_select "label[for=post_title] .fa-asterisk[aria-hidden=true]"
  end

  test "its text, options, a hash as options, and a block, as Rails'" do
    assert_select_in form.label(:body, "Text", class: "mine", data: {a: 1}), "label.mine.font-medium[for=post_body][data-a='1']", text: "Text"
    assert_select_in form.label(:body, class: "mine"), "label.mine[for=post_body]", text: "Body"
    assert_select_in form.label(:body) { |builder| "Custom #{builder.translation}" }, "label[for=post_body]", text: "Custom Body"
    assert_select_in form.label(:kind, value: "Some Value"), "label[for=post_kind_some_value]"
  end

  test "its text from helpers.label, as Rails'" do
    I18n.backend.store_translations(:en, helpers: {label: {post: {body: "The body", kind: {news: "Only news"}}}})
    assert_select_in form.label(:body), "label", text: "The body"
    assert_select_in form.label(:kind, value: "news"), "label", text: "Only news"
  ensure
    I18n.reload!
  end

  test "without a record" do
    builder = FormComponents::FormBuilder.new(:search, nil, vc_test_controller.view_context, {})
    assert_select_in builder.label(:query), "label[for=search_query]", text: "Query"
    assert_select_in builder.text_field(:query), "input[name='search[query]']"
  end

  def assert_select_in(html, selector, **)
    @rendered_content = html
    assert_select(selector, **)
  end

  def rendered_content = @rendered_content || super
end

class FieldExtrasTest < ComponentTest
  test "keeps aria attributes it's given" do
    render_inline FormComponents::TextField::Component.new(form, Post.new, :title, {"aria-describedby": "elsewhere", description: "Here"})

    assert_select "input[aria-describedby=elsewhere]"
  end

  test "a check box's and a radio button's label point at their input, also with an id of its own" do
    render_inline FormComponents::CheckBox::Component.new(form, Post.new, :published, {id: "mine"})
    assert_select "input#mine[type=checkbox]"
    assert_select "label[for=mine]", text: "Published"

    render_inline FormComponents::RadioButton::Component.new(form, Post.new, :kind, "Some Value", {label: "Some"})
    assert_select "input#post_kind_some_value"
    assert_select "label[for=post_kind_some_value]", text: "Some"
  end
end

class CollectionTest < ComponentTest
  test "a fieldset, its label as the legend, the description once and each item's own" do
    render_inline FormComponents::CollectionRadioButtons::Component.new(form, Post.new, :kind, Post::KINDS, :first, :second, {label: "Kind of post", description: "Pick one", description_method: :third})

    assert_select "fieldset[aria-describedby=post_kind_description] > legend", text: "Kind of post"
    assert_select "p#post_kind_description", text: "Pick one", count: 1
    assert_select "label[for=post_kind_news]", text: "News"
    assert_select "input#post_kind_news[aria-describedby=post_kind_news_description]"
    assert_select "label#post_kind_news_description", text: "What happened"
  end

  test "the legend is the attribute's name, marked when required, or none" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      validates :tags, presence: true
    end
    render_inline FormComponents::CollectionCheckBoxes::Component.new(form(post_class.new), post_class.new, :tags, Post::TAGS, :itself, :titleize)
    assert_select "legend", text: "Tags"
    assert_select "legend .fa-asterisk"

    render_inline FormComponents::CollectionCheckBoxes::Component.new(form, Post.new, :tags, Post::TAGS, :itself, :titleize, {label: false})
    assert_select "legend", count: 0
  end

  test "shows its errors once" do
    post = Post.new
    post.errors.add(:kind, :blank)
    render_inline FormComponents::CollectionRadioButtons::Component.new(form(post), post, :kind, Post::KINDS, :first, :second)

    assert_select "p#post_kind_error", text: "can't be blank", count: 1
    assert_select "input[type=radio][aria-invalid=true]", count: 3
  end
end

class SelectTest < ComponentTest
  test "a label pointing at the select, its description and errors" do
    post = Post.new
    post.errors.add(:category, :blank)
    render_inline FormComponents::Select::Component.new(form(post), post, :category, [["News"]], {description: "Pick one"}, {id: "mine"})

    assert_select "label[for=mine]", text: "Category"
    assert_select "select#mine[aria-invalid=true][aria-describedby=mine_error]"
    assert_select "p#mine_description", text: "Pick one"
    assert_select "p#mine_error", text: "can't be blank"
  end

  test "options depending on other fields: the groups as given, and the fields for the controller" do
    groups = [["Players", [["Keeper", "keeper"]], {data: {role: "player"}}], ["Staff", [["Doctor", "doctor"]], {data: {role: "staff", club_kind: "pro"}}]]
    html = form.select(:category, groups, {include_blank: true}, depends_on: [:role, :club_kind])
    fragment = Nokogiri::HTML5.fragment(html)

    wrapper = fragment.at_css("[data-controller='form-components--depends-on']")
    assert_equal [{"name" => "post[role]", "attribute" => "data-role"}, {"name" => "post[club_kind]", "attribute" => "data-club-kind"}],
      JSON.parse(wrapper["data-form-components--depends-on-fields-value"])
    assert wrapper.at_css("select[name='post[category]'] optgroup[label=Players][data-role=player] option[value=keeper]")
    assert wrapper.at_css("optgroup[label=Staff][data-role=staff][data-club-kind=pro]")
    assert_nil wrapper.at_css("select")["depends_on"]
  end

  test "depending on a field of the same row in a nested form" do
    html = form.fields_for(:sections, Section.new, child_index: "NEW_RECORD", builder: FormComponents::FormBuilder) { |row| row.select(:title, [], {}, depends_on: :role) }
    fields = JSON.parse(Nokogiri::HTML5.fragment(html).at_css("[data-form-components--depends-on-fields-value]")["data-form-components--depends-on-fields-value"])

    assert_equal "post[sections_attributes][NEW_RECORD][role]", fields.first["name"]
  end

  test "a select depending on nothing has no controller" do
    assert_not_includes form.select(:category, [["News"]]), "depends-on"
  end

  test "a combobox under our label, its own hidden" do
    html = form.combobox(:city, Post::CITIES, label: "Where", description: "Type to filter")
    fragment = Nokogiri::HTML5.fragment(html)

    assert_equal ["Where", nil], fragment.css("label[for=post_city]").map { |label| label.text.strip.presence }
    assert fragment.css("label[for=post_city]").last["hidden"]
    assert_equal "post_city_description", fragment.at_css("input#post_city")["aria-describedby"]
  end
end

class ScaleTest < ComponentTest
  test "a number on a scale: Rails' radio buttons, with labels at its ends" do
    render_inline FormComponents::ScaleField::Component.new(form(Post.new(score: 7)), Post.new(score: 7), :score, {in: 0..10, min_label: "Not likely", max_label: "Very likely"})

    assert_select "fieldset > legend", text: "Score"
    assert_select "input[type=radio][name='post[score]']", count: 11
    assert_select "input#post_score_7[value='7'][checked]"
    assert_select "label[for=post_score_0]", text: "0"
    assert_select "input[type=hidden][name='post[score]'][value='']"
    assert_select "span", text: "Not likely"
    assert_select "span", text: "Very likely"
  end

  test "1 to 5 unless given" do
    render_inline FormComponents::ScaleField::Component.new(form, Post.new, :score)
    assert_equal %w[1 2 3 4 5], Nokogiri::HTML5.fragment(rendered_content).css("input[type=radio]").map { |input| input["value"] }
  end
end

class RatingTest < ComponentTest
  test "stars from 1 to max, each a radio button with its number for screen readers" do
    render_inline FormComponents::RatingField::Component.new(form(Post.new(rating: 4)), Post.new(rating: 4), :rating, {max: 10, description: "How good"})

    assert_select "fieldset[aria-describedby=post_rating_description] > legend", text: "Rating"
    assert_select "input[type=radio][name='post[rating]']", count: 10
    assert_select "input#post_rating_4[checked]"
    assert_select "label[for=post_rating_1] svg[aria-hidden=true]"
    assert_select "label[for=post_rating_1] .sr-only", text: "1"
  end

  test "five unless given, and errors on each star" do
    post = Post.new
    post.errors.add(:rating, :blank)
    render_inline FormComponents::RatingField::Component.new(form(post), post, :rating)

    assert_select "input[type=radio][aria-invalid=true]", count: 5
    assert_select "p#post_rating_error", text: "can't be blank"
  end
end

class TelephoneFieldTest < ComponentTest
  def field(phone, **options)
    Nokogiri::HTML5.fragment(form(Post.new(phone: phone)).telephone_field(:phone, **options))
  end

  test "the number's country, from its code" do
    html = field("+32 470 12 34 56")
    assert_equal "470123456", html.at_css("input[type=tel]")["value"]
    assert html.at_css("button .fi.fi-be")
    assert_equal "+32", html.at_css("[data-form-components--telephone-field-target=code]").text
    assert_equal "+32 470 12 34 56", html.at_css("input[type=hidden]")["value"]
  end

  test "a code that several countries share: the default's, a priority one's, else the main one's" do
    assert field("+14165551234").at_css(".fi-us")
    assert field("+14165551234", country: "ca").at_css(".fi-ca")
    assert field("+14165551234", priority_countries: %w[ca]).at_css(".fi-ca")
    assert field("004420 7946 0000").at_css(".fi-gb")
  end

  test "a number without a code is shown as it is, with the default country" do
    html = field("0123456789")
    assert_equal "0123456789", html.at_css("input[type=tel]")["value"]
    assert html.at_css("button .fi-nl")
    assert field(nil, country: "DE").at_css("button .fi-de")
  end

  test "the label is the number's, which is required, and the hidden field isn't" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      validates :phone, presence: true
    end
    html = Nokogiri::HTML5.fragment(form(post_class.new).telephone_field(:phone))

    assert html.at_css("label[for=post_phone]")
    assert html.at_css("input#post_phone[type=tel][required]:not([name])")
    assert_nil html.at_css("input[type=hidden]")["required"]
  end

  test "the priority countries, for the controller to put on top" do
    html = field(nil, priority_countries: %w[NL be xx])
    assert_equal %w[nl be].to_json, html.at_css("[data-form-components--telephone-field-priority-value]")["data-form-components--telephone-field-priority-value"]
  end
end

class RichTextAreaTest < ComponentTest
  def field(post = Post.new(notes: "<p>Hi</p>"), method = :notes, **options)
    Nokogiri::HTML5.fragment(form(post).rich_text_area(method, **options))
  end

  def data(html, name) = html.at_css("[data-controller]")["data-form-components--rich-text-area-#{name}-value"]

  test "the HTML in Rails' text area, which the label points at, out of sight and handing its focus to the editor" do
    html = field
    textarea = html.at_css("textarea#post_notes[name='post[notes]'][tabindex='-1'][aria-hidden=true]")

    assert_equal "<p>Hi</p>", textarea.text
    assert_includes textarea["data-action"], "focus->form-components--rich-text-area#focus"
    assert html.at_css("label#post_notes_label[for=post_notes]")
    assert_equal "post_notes_editor", JSON.parse(data(html, "attributes"))["id"]
    assert_equal "post_notes_label", JSON.parse(data(html, "attributes"))["aria-labelledby"]
  end

  test "the default toolbar, with the image button when the host has Active Storage" do
    html = field

    assert html.at_css("[role=toolbar] select[data-form-components--rich-text-area-target=heading]")
    assert_equal %w[bold italic underline strike link bullet_list ordered_list blockquote image undo redo], html.css("[role=toolbar] button").map { |button| button["data-command"] }
    assert_equal 5, html.css("[role=toolbar] > span[aria-hidden]").size
    assert_equal FormComponents::RichTextArea::Component.default_toolbar.without(:|).map(&:to_s), JSON.parse(data(html, "toolbar"))
    assert_equal "http://test.host/rails/active_storage/direct_uploads", data(html, "direct-upload-url")
    assert html.at_css("input[type=file][accept='image/*']")
  end

  test "a toolbar of its own, without separators at the ends or next to each other, or none" do
    html = field(toolbar: %i[| bold | | code_block align_center |])

    assert_equal %w[bold code_block align_center], html.css("[role=toolbar] button").map { |button| button["data-command"] }
    assert_equal 1, html.css("[role=toolbar] > span[aria-hidden]").size
    assert_nil html.at_css("[data-form-components--rich-text-area-target=linkMenu]")
    assert_nil field(toolbar: false).at_css("[role=toolbar]")
    assert_raises(ArgumentError) { field(toolbar: %i[bold blink]) }
  end

  test "no image button nor uploads without a direct upload URL" do
    html = field(toolbar: %i[bold image], data: {direct_upload_url: nil})

    assert_equal %w[bold], html.css("[role=toolbar] button").map { |button| button["data-command"] }
    assert_nil data(html, "direct-upload-url")
    assert_nil html.at_css("input[type=file]")
  end

  test "required: the text area, for the browser to check, and the editor" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      validates :notes, presence: true
    end

    html = field(post_class.new)
    assert html.at_css("textarea[required]")
    assert_equal "true", JSON.parse(data(html, "attributes"))["aria-required"]
    assert_nil field(post_class.new, required: false).at_css("textarea[required]")
  end

  test "placeholder, class and disabled are the editor's" do
    html = field(placeholder: "Write", class: "min-h-64", disabled: true)

    assert_equal "Write", data(html, "placeholder")
    assert_includes JSON.parse(data(html, "attributes"))["class"], "min-h-64"
    assert_equal "true", data(html, "disabled")
    assert html.at_css("textarea[disabled]:not([placeholder])")
  end

  test "an Action Text attribute, with its images as <img data-sgid> and its other attachments left out" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("png"), filename: "a b.png", content_type: "image/png")
    pdf = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("pdf"), filename: "a.pdf", content_type: "application/pdf")
    article = Article.new(content: %(<p>Hi</p><action-text-attachment sgid="#{blob.attachable_sgid}" caption="A cat"></action-text-attachment><action-text-attachment sgid="#{pdf.attachable_sgid}"></action-text-attachment>))
    html = Nokogiri::HTML5.fragment(FormComponents::FormBuilder.new(:article, article, vc_test_controller.view_context, {}).rich_text_area(:content))

    assert_equal "true", data(html, "action-text")
    value = Nokogiri::HTML5.fragment(html.at_css("textarea[name='article[content]']").text)
    img = value.at_css("img")
    assert_equal [blob.attachable_sgid, "image/png", "a b.png", "A cat"], [img["data-sgid"], img["data-content-type"], img["data-filename"], img["alt"]]
    assert_equal "http://test.host/rails/active_storage/blobs/redirect/#{blob.signed_id}/a%20b.png", img["src"]
    assert_equal 1, value.css("img").size
    assert_nil value.at_css("action-text-attachment")
  end

  test "what the controller sends for an Action Text attribute is its content" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("png"), filename: "a.png", content_type: "image/png")
    article = Article.create!(content: %(<p>Hi</p><action-text-attachment sgid="#{blob.attachable_sgid}" content-type="image/png" url="/x" filename="a.png"></action-text-attachment>))

    assert_equal [blob], article.content.body.attachables
    assert_includes article.content.to_plain_text, "Hi"
  end
end

class CodeEditorTest < ComponentTest
  test "Rails' text area with the code, out of sight, for the controller to edit in CodeMirror" do
    post = Post.new(query: "select 1")
    html = Nokogiri::HTML5.fragment(form(post).code_editor(:query, lang: :sql, height: "20rem", description: "SQL"))

    wrapper = html.at_css(".form-component[data-controller='form-components--code-editor']")
    assert_equal "sql", wrapper["data-form-components--code-editor-lang-value"]
    assert_equal "20rem", wrapper["data-form-components--code-editor-height-value"]
    assert_equal "false", wrapper["data-form-components--code-editor-read-only-value"]
    assert_equal({"id" => "post_query_editor", "aria-labelledby" => "post_query_label", "aria-describedby" => "post_query_description", "aria-invalid" => "false"},
      JSON.parse(wrapper["data-form-components--code-editor-attributes-value"]))

    textarea = html.at_css("textarea#post_query[name='post[query]'][tabindex='-1'][aria-hidden=true][data-form-components--code-editor-target=input]")
    assert_equal "select 1", textarea.text.strip
    assert html.at_css("label#post_query_label[for=post_query]")
    assert html.at_css("p#post_query_description", text: "SQL")
  end

  test "as Satis' editor, read-only when readonly or disabled, and only its languages" do
    assert_includes form.editor(:query), "form-components--code-editor"
    assert_includes form.code_editor(:query, readonly: true), "data-form-components--code-editor-read-only-value=\"true\""
    assert_includes form.code_editor(:query, disabled: true), "data-form-components--code-editor-read-only-value=\"true\""
    assert_raises(ArgumentError) { form.code_editor(:query, lang: :cobol) }
  end

  test "its errors and required" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      validates :query, presence: true
    end
    post = post_class.new
    post.validate
    html = Nokogiri::HTML5.fragment(form(post).code_editor(:query))

    attributes = JSON.parse(html.at_css("[data-form-components--code-editor-attributes-value]")["data-form-components--code-editor-attributes-value"])
    assert_equal ["true", "true", "post_query_error"], attributes.values_at("aria-required", "aria-invalid", "aria-describedby")
    assert html.at_css("textarea[required]")
    assert html.at_css("p#post_query_error")
  end
end

class SignatureFieldTest < ComponentTest
  test "a pad labelled as the field, and Rails' file field for the SVG, out of sight" do
    html = Nokogiri::HTML5.fragment(form.signature_field(:logo, width: 300, height: 100, description: "Sign here"))

    assert html.at_css("[data-controller='form-components--signature-field'][data-form-components--signature-field-read-only-value=false]")
    assert html.at_css("label#post_logo_label[for=post_logo_pad]", text: "Logo")
    pad = html.at_css("div[style='width: 300px; aspect-ratio: 300 / 100'] canvas#post_logo_pad[role=img][aria-labelledby=post_logo_label][aria-describedby=post_logo_description]")
    assert pad
    assert html.at_css("input[type=file][name='post[logo]'][accept='image/svg+xml'].hidden[data-form-components--signature-field-target=file]:not([required])")
    assert_equal 3, html.css("button[data-action^='form-components--signature-field#']").size
    assert_nil html.at_css("img")
    assert_nil html.at_css("input[name='post[remove_logo]']")
  end

  test "as Satis' signature, read-only without buttons, and a remove field when the record takes one" do
    assert_includes form.signature(:logo), "form-components--signature-field"
    assert_empty Nokogiri::HTML5.fragment(form.signature_field(:logo, disabled: true)).css("button")

    post_class = Class.new(Post) do
      def self.name = "Post"
      attr_accessor :remove_logo
    end
    html = Nokogiri::HTML5.fragment(form(post_class.new).signature_field(:logo))
    assert html.at_css("input[type=hidden][name='post[remove_logo]'][value='0'][data-form-components--signature-field-target=remove]")
  end
end
