# TwitterScrapper

Twitter Scrapper scrapes through a user's twitter html page and parses the
tweets and stores them into database(postgres) using ecto. The username is
provided at runtime to scrapper.

This scrapper is a html based scrapper and does not require any authentication.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `twitter_scrapper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:twitter_scrapper, "~> 0.1.0"}
  ]
end
```

## Environment details:
  elixir: 1.8
  erlang otp: 21

## Steps to follow:
  1. Make sure your postgres server is running.
  2. Change the configurations username, password and hostname according to your
     postgres server details. Config file: twitter_scrapper/config/config.exs
  3. Get the dependencies ```mix deps.get```
  4. Compile the dependencies ```mix deps.compile```
  5. Change the configurations `timeout`, `tokens_per_window` in config file if required.
      - `timeout` corresponds to the time window after which the tokens available
        are reset.
      - `tokens_per_window` corresponds to the max number of tokens available in
        a time window.
  6. Create a database `twitter_scrapper_repo` using ```mix ecto.create```
  7. Create a table `tweets` in the database using ```mix ecto.migrate```
  8. Start the app - `iex -S mix`
  9. Start scrapping:
    ```elixir
    :iex> TwitterScrapper.start_scrapping(<username here> eg. "mkbhd")
    ```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/twitter_scrapper](https://hexdocs.pm/twitter_scrapper).
