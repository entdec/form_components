# frozen_string_literal: true

class Section
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :_destroy, :boolean

  def self.model_name = ActiveModel::Name.new(self, nil, "Section")

  def new_record? = true
end
