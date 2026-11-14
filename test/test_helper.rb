# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"

require "rails/test_help"
require "rails-dom-testing"
require "view_component/test_helpers"

class ComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers
  include Rails::Dom::Testing::Assertions

  def form(post = Post.new, builder: FormComponents::FormBuilder, **options)
    builder.new(:post, post, vc_test_controller.view_context, options)
  end

  # The same form with Rails' own builder
  def rails_form(post = Post.new, **options)
    form(post, builder: ActionView::Helpers::FormBuilder, **options)
  end

  def document_root_element = Nokogiri::HTML5("<body>#{rendered_content}</body>").at("body")
end
