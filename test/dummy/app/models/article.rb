# frozen_string_literal: true

# A record with an Action Text attribute, for the rich text area
class Article < ActiveRecord::Base
  has_rich_text :content
end
