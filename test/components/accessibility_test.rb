# frozen_string_literal: true

require "test_helper"

# What the fields tell screen readers and keyboard users, as the W3C's forms
# tutorial has it (https://www.w3.org/WAI/tutorials/forms/)
class AccessibilityTest < ComponentTest
  test "an input is described by its errors and its description" do
    post = Post.new
    post.validate
    render_inline FormComponents::TextField::Component.new(form(post), post, :title, description: "Shown on top")

    assert_select "input#post_title[aria-describedby='post_title_error post_title_description']"
    assert_select "p#post_title_description", text: "Shown on top"
    assert_select "p#post_title_error", text: "can't be blank"
  end

  test "a label for screen readers only, with hide_label:" do
    render_inline FormComponents::TextField::Component.new(form, Post.new, :title, hide_label: true)
    assert_select "label.sr-only[for=post_title]", text: "Title"
    assert_select "input[hide_label]", count: 0

    render_inline FormComponents::RichTextArea::Component.new(form, Post.new, :notes, hide_label: true)
    assert_select "label#post_notes_label.sr-only[for=post_notes]"

    render_inline FormComponents::CollectionRadioButtons::Component.new(form, Post.new, :kind, Post::KINDS, :first, :second, {hide_label: true})
    assert_select "legend.sr-only", text: "Kind"
  end

  test "a check box's and a radio button's description describes it, without labelling it again" do
    render_inline FormComponents::CheckBox::Component.new(form, Post.new, :published, {description: "Shown on the site"})
    assert_select "input[type=checkbox][aria-describedby=post_published_description]"
    assert_select "p#post_published_description", text: "Shown on the site"
    assert_select "label", count: 1

    render_inline FormComponents::RadioButton::Component.new(form, Post.new, :visibility, "public", {description: "Anyone"})
    assert_select "p#post_visibility_public_description", text: "Anyone"
    assert_select "label", count: 1
  end

  test "a radio button can't have aria-required: its label says it" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      attr_accessor :listed
      validates :visibility, presence: true, if: :listed
    end
    render_inline FormComponents::RadioButton::Component.new(form(post_class.new), post_class.new, :visibility, "public")

    assert_select "input[type=radio]:not([aria-required]):not([required])"
    assert_select "label .sr-only", text: "(required)"
  end

  test "decorative icons are hidden from screen readers" do
    post = Post.new
    post.validate
    render_inline FormComponents::TextField::Component.new(form(post), post, :title, leading_icon: "fas fa-heading")

    assert_select ".fa-heading[aria-hidden=true]"
    assert_select ".fa-circle-exclamation[aria-hidden=true]"
    assert_select "[class*=fa-]:not([aria-hidden])", count: 0
  end

  test "a scale's end labels describe the numbers at its ends" do
    render_inline FormComponents::ScaleField::Component.new(form, Post.new, :score, {in: 0..10, min_label: "Not likely", max_label: "Very likely"})

    assert_select "span#post_score_min_label", text: "Not likely"
    assert_select "span#post_score_max_label", text: "Very likely"
    assert_select "input#post_score_0[aria-describedby=post_score_min_label]"
    assert_select "input#post_score_10[aria-describedby=post_score_max_label]"
    assert_select "input#post_score_5:not([aria-describedby])"
  end

  test "a country field's toggle is named by its label and the country picked" do
    render_inline FormComponents::CountryField::Component.new(form(Post.new(country: "NL")), Post.new(country: "NL"), :country)

    assert_select "label#post_country_label[for=post_country]"
    assert_select "button#post_country[aria-labelledby='post_country_label post_country_value']"
    assert_select "span#post_country_value", text: "NL"

    render_inline FormComponents::CountryField::Component.new(form, Post.new, :country, {label: false})
    assert_select "button#post_country[aria-labelledby=post_country_value]"
  end

  test "a rich text area's toolbar is named" do
    render_inline FormComponents::RichTextArea::Component.new(form, Post.new, :notes)

    assert_select "[role=toolbar][aria-label=Formatting][aria-controls=post_notes_editor][data-action*=toolbarKeydown]"
  end

  test "a signature field's menu is a disclosure, not an ARIA menu without its keys" do
    render_inline FormComponents::SignatureField::Component.new(form, Post.new, :logo)

    assert_select "button[aria-expanded=false][aria-controls=post_logo_menu]:not([aria-haspopup])"
    assert_select "#post_logo_menu[hidden]:not([role]) button:not([role])", count: 2
  end
end

class ErrorSummaryTest < ComponentTest
  test "nothing without errors" do
    render_inline FormComponents::ErrorSummary::Component.new(form, Post.new)

    assert_equal "", rendered_content
  end

  test "the errors, each a link to its field, focused" do
    post = Post.new(color: "red")
    post.validate
    post.errors.add(:base, "Something else")
    render_inline FormComponents::ErrorSummary::Component.new(form(post), post)

    assert_select ".form-error-summary[role=region][tabindex='-1'][autofocus][aria-labelledby=post_error_summary_title]"
    assert_select "h2#post_error_summary_title", text: "There are 3 errors in this form"
    assert_select "li a[href='#post_title']", text: "Title can't be blank"
    assert_select "li a[href='#post_color']", text: "Color is invalid"
    assert_select "li", text: "Something else"
    assert_select "li a", count: 2
  end

  test "with a title, one error, its own options" do
    post = Post.new
    post.validate
    render_inline FormComponents::ErrorSummary::Component.new(form(post), post, {title: "Not saved", class: "mb-4", id: "errors"})
    assert_select "#errors.form-error-summary.mb-4 h2", text: "Not saved"

    render_inline FormComponents::ErrorSummary::Component.new(form(post), post)
    assert_select "h2", text: "There is 1 error in this form"
  end

  test "f.error_summary" do
    post = Post.new
    post.validate

    assert_includes form(post).error_summary, "Title can&#39;t be blank"
    assert_nil Nokogiri::HTML5.fragment(form.error_summary.to_s).at_css("div")
  end
end
