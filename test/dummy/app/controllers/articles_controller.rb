# frozen_string_literal: true

# The rich text area on an Action Text attribute, and how its content renders
class ArticlesController < ApplicationController
  def new
    @article = Article.new
    render :edit
  end

  def create
    @article = Article.create!(article_params)
    redirect_to edit_article_path(@article)
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    @article.update!(article_params)
    redirect_to edit_article_path(@article)
  end

  private

  def article_params = params.expect(article: %i[title content])
end
