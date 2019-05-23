# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :twitter_scrapper, TwitterScrapper.Repo,
  database: "twitter_scrapper_repo",
  username: "postgres",
  password: "root",
  hostname: "localhost"

config :twitter_scrapper,
  ecto_repos: [TwitterScrapper.Repo],
  rate_limiter: [
    timeout: 15,
    tokens_per_window: 5
  ]

config :twitter_feed,
  twitter_api: TwitterFeed.TwitterApi.HttpClient
