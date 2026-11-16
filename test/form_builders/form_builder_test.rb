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

  def required_attribute?(html) = Nokogiri::HTML5.fragment(html).css("[required]").any?

  test "an input the record must have filled in now is required, for the browser to check" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      attr_accessor :listed
      validates :body, presence: true, if: :listed
      validates :email, presence: true, unless: -> { listed }
      validates :kind, :rating, :published, :tags, :logo, :city, presence: true
    end
    post = post_class.new

    assert required_attribute?(form(post).text_field(:title))
    assert_not required_attribute?(form(post).text_field(:title, required: false))
    assert_not required_attribute?(form(post).text_area(:body))
    assert required_attribute?(form(post_class.new(listed: true)).text_area(:body))
    assert required_attribute?(form(post).email_field(:email))
    assert_not required_attribute?(form(post_class.new(listed: true)).email_field(:email))
    assert_not required_attribute?(form(post).text_field(:phone))

    assert_equal 2, Nokogiri::HTML5.fragment(form(post).collection_radio_buttons(:kind, Post::KINDS.first(2), :first, :second)).css("input[type=radio][required]").size
    assert_equal 5, Nokogiri::HTML5.fragment(form(post).rating_field(:rating)).css("input[type=radio][required]").size
    assert required_attribute?(form(post).check_box(:published))
    assert Nokogiri::HTML5.fragment(form(post).combobox(:city, Post::CITIES)).at_css("input[role=combobox][required]")
    # Not each of several check boxes, nor a file that may be there already
    assert_empty Nokogiri::HTML5.fragment(form(post).collection_check_boxes(:tags, Post::TAGS, :itself, :itself)).css("[required]")
    assert_not required_attribute?(form(post).check_box(:tags, {multiple: true}, "ruby", nil))
    assert_not required_attribute?(form(post).file_field(:logo))
  end

  test "an input required but not for the browser to check says so to screen readers" do
    post_class = Class.new(Post) do
      def self.name = "Post"
      attr_accessor :listed
      validates :body, presence: true, if: :listed
      validates :tags, :logo, :kind, :country, presence: true
    end
    post = post_class.new
    fragment = ->(html) { Nokogiri::HTML5.fragment(html) }

    # aria-required, as its asterisk says, where the browser doesn't check it
    assert fragment.call(form(post).text_area(:body)).at_css("textarea[aria-required=true]:not([required])")
    assert_nil fragment.call(form(post).text_field(:title)).at_css("[aria-required]")
    assert_nil fragment.call(form(post).text_area(:body, required: false)).at_css("[aria-required]")
    # The label or legend says it where an input can't have aria-required
    assert_equal "Logo (required)", fragment.call(form(post).file_field(:logo)).at_css("label").text
    assert_equal "Country (required)", fragment.call(form(post).country_field(:country)).at_css("label").text
    assert_equal "Tags (required)", fragment.call(form(post).collection_check_boxes(:tags, Post::TAGS, :itself, :itself)).at_css("legend").text
    # Not where each radio button is required
    assert_equal "Kind", fragment.call(form(post).collection_radio_buttons(:kind, Post::KINDS, :first, :second)).at_css("legend").text
    assert_equal "Title", fragment.call(form(post).text_field(:title)).at_css("label").text
  end
end

class FormBuilderRegisterTest < ComponentTest
  class Greeting < ViewComponent::Base
    def initialize(form:, attribute:, greeting: "Hello")
      @form = form
      @attribute = attribute
      @greeting = greeting
    end

    def call
      tag.p("#{@greeting}, #{@form.object.public_send(@attribute)}#{content}", id: @form.field_id(@attribute, :greeting))
    end
  end

  setup do
    FormComponents::FormBuilder.register(:greeting) do |method = :title, **options|
      Greeting.new(form: self, attribute: method, **options)
    end
  end

  teardown do
    FormComponents::FormBuilder.remove_method(:greeting)
  end

  test "a helper for an app's component, with its arguments, rendered with its block as content" do
    f = form(Post.new(title: "World", body: "Body"))

    assert_select_in f.greeting, "p#post_title_greeting", text: "Hello, World"
    assert_select_in f.greeting(:body, greeting: "Hi"), "p#post_body_greeting", text: "Hi, Body"
    assert_select_in f.greeting { "!" }, "p", text: "Hello, World!"
  end

  test "registered again, replaced" do
    FormComponents::FormBuilder.register(:greeting) { |method = :title| Greeting.new(form: self, attribute: method, greeting: "Bye") }

    assert_select_in form(Post.new(title: "World")).greeting, "p", text: "Bye, World"
  end

  test "needs a block" do
    assert_raises(ArgumentError) { FormComponents::FormBuilder.register(:greeting) }
  end

  def assert_select_in(html, selector, **)
    @rendered_content = html
    assert_select(selector, **)
  end

  def rendered_content = @rendered_content || super
end
