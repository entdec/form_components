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
