# frozen_string_literal: true

# A record with an attribute for every kind of field
class Post
  include ActiveModel::Model
  include ActiveModel::Attributes

  KINDS = [["news", "News", "What happened"], ["blog", "Blog", "What we think"], ["some value", "Some value", "With a space"]].freeze
  TAGS = %w[ruby rails tailwind].freeze
  LANGUAGES = [["en", "English"], ["nl", "Dutch"], ["de", "German"]].freeze
  CITIES = %w[Amsterdam Rotterdam Utrecht Groningen Maastricht].freeze

  attribute :title, :string
  attribute :body, :string
  attribute :email, :string
  attribute :password, :string
  attribute :phone, :string
  attribute :website, :string
  attribute :count, :integer
  attribute :starts_on, :date
  attribute :starts_at, :datetime
  attribute :color, :string
  attribute :published, :boolean
  attribute :kind, :string
  attribute :visibility, :string
  attribute :tags, default: -> { [] }
  attribute :category, :string
  attribute :language, :string
  attribute :city, :string
  attribute :time_zone, :string
  attribute :rating, :integer
  attribute :score, :integer
  attribute :logo

  validates :title, presence: true
  validates :color, format: {with: /\A#\h{6}\z/}, allow_blank: true

  attr_writer :sections

  def self.model_name = ActiveModel::Name.new(self, nil, "Post")

  def sections = @sections || []

  def sections_attributes=(attributes)
  end
end
