defmodule TwitterScrapper.Repo.Migrations.CreateTweets do
  use Ecto.Migration

  def change do
    create table(:tweets) do
      add :author_name, :string
      add :tweet_text, :string
      add :likes, :integer
      add :replies, :integer
      add :retweets, :integer
      add :date_time_stamp, :string
    end
  end
end
