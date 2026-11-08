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
end
