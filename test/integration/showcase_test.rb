# frozen_string_literal: true

require "test_helper"

# The dummy app's page, and what its form sends
class ShowcaseTest < ActionDispatch::IntegrationTest
  test "every component on the page" do
    get root_path

    assert_response :success
    %w[post[title] post[email] post[body] post[published] post[kind] post[visibility] post[tags][] post[color] post[logo] post[category] post[language] post[time_zone] post[city] post[rating] post[score]].each do |name|
      assert_select "[name='#{name}']", {minimum: 1}, name
    end
    assert_select ".section-wrapper [data-action='form-components--nested-form#remove']", minimum: 1
  end

  test "the form sends what Rails' fields send" do
    post posts_path, params: {post: {title: "Hi", published: "1", kind: "blog", tags: ["", "ruby", "rails"], starts_on: "2026-11-14"}}

    assert_response :success
    assert_select "pre", text: /"tags": \[\s*"",\s*"ruby",\s*"rails"\s*\]/
    assert_select "input#post_kind_blog[checked]"
    assert_select "input#post_tags_ruby[checked]"
  end
end
