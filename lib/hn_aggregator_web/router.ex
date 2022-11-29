defmodule HnAggregatorWeb.Router do
  use HnAggregatorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", HnAggregatorWeb do
    pipe_through :api

    get "/top_stories", AggregatorController, :top_stories
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
    end
  end
end
