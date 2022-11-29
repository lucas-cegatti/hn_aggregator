defmodule HnAggregatorWeb.AggregatorView do
  use HnAggregatorWeb, :view

  def render("top_stories.json", %{top_stories: top_stories, next_page: next_page}) do
    %{
      data: render_many(top_stories, HnAggregatorWeb.AggregatorView, "top_story.json"),
      next_page: next_page
    }
  end

  def render("top_story.json", %{aggregator: top_story}) do
    %{
      id: top_story.id,
      detail_url: top_story.detail_url,
      expired_data: top_story.expired_data
    }
  end

  def render("error.json", %{message: message}) do
    %{
      type: :error,
      message: message
    }
  end
end
