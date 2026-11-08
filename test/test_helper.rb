# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "active_model"
require "form_components"

# A Rails app just big enough to render the components
class TestApp < Rails::Application
  config.root = File.expand_path("..", __dir__)
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "test"
end
Rails.application.initialize!
Rails.application.routes.draw {}

# The controller the components are rendered with in tests
class ApplicationController < ActionController::Base
end

require "minitest/autorun"
require "rails-dom-testing"
require "view_component/test_helpers"

# A record for the components' forms
class Post
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :body, :string
  attribute :color, :string
  attribute :published, :boolean
  attribute :kind, :string

  validates :title, presence: true
  validates :color, format: {with: /\A#\h{6}\z/}, allow_blank: true

  attr_writer :sections

  def self.model_name = ActiveModel::Name.new(self, nil, "Post")

  def sections = @sections || []

  def sections_attributes=(attributes)
  end
end

class Section
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string

  def self.model_name = ActiveModel::Name.new(self, nil, "Section")

  def new_record? = true
end

class ComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers
  include Rails::Dom::Testing::Assertions

  def form(post = Post.new, **options)
    FormComponents::FormBuilder.new(:post, post, vc_test_controller.view_context, options)
  end

  def document_root_element = Nokogiri::HTML5("<body>#{rendered_content}</body>").at("body")
end
