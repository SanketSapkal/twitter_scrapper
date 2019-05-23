defmodule TwitterScrapper.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {TwitterScrapper.Repo, []},
      {TwitterScrapper, []},
      {TwitterScrapper.RateLimiter, []}
    ]

    opts = [strategy: :one_for_one, name: TwitterScrapper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
