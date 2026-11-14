# frozen_string_literal: true

# Every component on one page, and what the form sends back
class ShowcaseController < ApplicationController
  def show
    @post = Post.new(title: "Hello", kind: "news", tags: ["ruby"], color: "#1e40af", sections: [Section.new(title: "Intro")])
  end

  def create
    @params = params.require(:post).permit!.to_h
    @post = Post.new(@params.except("sections_attributes", "logo"))
    @post.validate
    render :show, status: (@post.errors.any? ? :unprocessable_content : :ok)
  end
end
