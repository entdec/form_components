# frozen_string_literal: true

require "test_helper"

class FormBuilderTest < ComponentTest
  test "renders its fields as components" do
    html = form(Post.new(title: "Hello")).text_field(:title)

    assert_includes html, "name=\"post[title]\""
    assert_includes html, "outline-gray-300"
  end

  test "text fields of a type" do
    assert_includes form.email_field(:title), "type=\"email\""
    assert_includes form.datetime_local_field(:title), "type=\"datetime-local\""
  end

  test "makes the form multipart for a file field" do
    builder = form
    assert_not builder.multipart
    builder.file_field(:body)
    assert builder.multipart
  end

  test "the validation context decides what's required" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      validates :body, presence: true, on: :publish
    end

    assert_not_includes form(post_class.new).label(:body), "fa-asterisk"
    assert_includes form(post_class.new, validation_context: :publish).label(:body), "fa-asterisk"
  end

  test "an input the record must have filled in now is required, for the browser to check" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      attr_accessor :listed
      validates :body, presence: true, if: :listed
      validates :email, presence: true, unless: -> { listed }
      validates :kind, :rating, :published, :tags, :logo, :city, presence: true
    end
    post = post_class.new

    assert_includes form(post).text_field(:title), "required"
    assert_not_includes form(post).text_field(:title, required: false), "required"
    assert_not_includes form(post).text_area(:body), "required"
    assert_includes form(post_class.new(listed: true)).text_area(:body), "required"
    assert_includes form(post).email_field(:email), "required"
    assert_not_includes form(post_class.new(listed: true)).email_field(:email), "required"
    assert_not_includes form(post).text_field(:phone), "required"

    assert_equal 2, Nokogiri::HTML5.fragment(form(post).collection_radio_buttons(:kind, Post::KINDS.first(2), :first, :second)).css("input[type=radio][required]").size
    assert_equal 5, Nokogiri::HTML5.fragment(form(post).rating_field(:rating)).css("input[type=radio][required]").size
    assert_includes form(post).check_box(:published), "required"
    assert Nokogiri::HTML5.fragment(form(post).combobox(:city, Post::CITIES)).at_css("input[role=combobox][required]")
    # Not each of several check boxes, nor a file that may be there already
    assert_empty Nokogiri::HTML5.fragment(form(post).collection_check_boxes(:tags, Post::TAGS, :itself, :itself)).css("[required]")
    assert_not_includes form(post).check_box(:tags, {multiple: true}, "ruby", nil), "required"
    assert_not_includes form(post).file_field(:logo), "required"
  end
end
