defmodule TwitterScrapperTest do
  use ExUnit.Case
  doctest TwitterScrapper

  @tag timeout: 600000
  test "test scrapping" do
    TwitterScrapper.Repo.delete_all(TwitterScrapper.Tweet)
    assert TwitterScrapper.start_scrapping("mkbhd", 60) == :ok
    :timer.sleep(:timer.seconds(30))
    assert length(TwitterScrapper.show_all_tweets) == 60
  end
end
