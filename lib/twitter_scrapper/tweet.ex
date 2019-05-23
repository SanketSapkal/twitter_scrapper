defmodule TwitterScrapper.Tweet do
  use Ecto.Schema

  schema "tweets" do
    field :author_name, :string
    field :tweet_text, :string
    field :likes, :integer
    field :replies, :integer
    field :retweets, :integer
    field :date_time_stamp, :string
  end
end
