# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title
    end
  end
end
