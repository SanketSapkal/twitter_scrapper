defmodule TwitterScrapper.Repo do
  use Ecto.Repo,
    otp_app: :twitter_scrapper,
    adapter: Ecto.Adapters.Postgres
end
