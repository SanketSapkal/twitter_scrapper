defmodule TwitterScrapper do
  @moduledoc """
  Twitter Scrapper scrapes through a user's twitter html page and parses the
  tweets and stores them into database(postgres) using ecto.
  The tweets are scraped and parsed by :twitter_feed dependency.
  The parsed tweets are then translated to %TwitterScrapper.Tweet and inserted into database.

  Username is not hardcoded, tweets for different users can be scraped during runtime.

  TwitterScrapper uses a GenServer instead of a normal application to facilitate
  asynchronous scrapping of tweets.

  Twitter Scrapper also periodically resets the available tokens in
  TwitterScrapper.RateLimiter agent. The period is specified in timeout config variable.

  The scrapping occurs in iterations, each iteration scrapes for 20 tweets and
  stores it in the database and the next_scrape iteration is started. The next_scrape
  iteration is skipped if there are no available tokens from rate_limiter agent.
  The next_scrape iteration goes on unitl either of the conditions are met:
    - No more tokens are available in rate_limiter agent.
    - No more tweets to scrape. (more_tweets? denotes this in %TwitterFeed.Feed)
    - Count specified by user has been reached.
  """

  use GenServer

  require Ecto.Query

  alias TwitterScrapper.RateLimiter

  @default_count 20
  @zero_index 0

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :twitter_scrapper)
  end

  def init(state) do
    # Send first reset from here or the start the reseting process.
    reset_rate_limiter()
    {:ok, state}
  end

  @doc """
  Function call to start scrapping.
  # Parameters acceepted:
  - user_name: user_name of the author of which tweets are to be scrapped.
  - count: Total number of tweets to be scrapped.
  - last_tweet_id: offset from where the scrapping is to be started.

  Casts a message to the :twitter_scrapper to start scrapping, which further sends a message.

  ## Examples:
      :iex> TwitterScrapper.start_scrapping("mkbhd")
  """
  @spec start_scrapping(String.t, integer, integer) :: :ok
  #
  # Cast a message to start_scrapping.
  #
  def start_scrapping(user_name, count \\ @default_count, last_tweet_id \\ 0) do
    GenServer.cast(:twitter_scrapper, {:start_scrapping, {user_name, count, last_tweet_id}})
  end

  @doc """
  Function call to show the whole table.

  ## Examples:
      :iex> TwitterScrapper.show_all_tweets()
  """
  @spec show_all_tweets() :: [%TwitterScrapper.Tweet{}]
  def show_all_tweets() do
    TwitterScrapper.Tweet |> TwitterScrapper.Repo.all
  end

  #
  # Send a message to self to scrape with parameters, the scrapping happens asynchronously.
  #
  def handle_cast({:start_scrapping, {username, count, last_tweet_id}}, state) do
    # Send a message to self to scrape with parameters, the scrapping happens asynchronously.
    Process.send(self(), {:scrape, {username, count, last_tweet_id}}, [])
    {:noreply, state}
  end

  #
  # Received a message to scrape, but the number of tweets scrapped and stored
  # into the data is equal to count specified by the user, so no need scrape more.
  #
  def handle_info({:scrape, {_username, count, _last_tweet_id}}, state) when count <= 0 do
    IO.puts("More tweets to scrape but count is satisfied.")
    {:noreply, state}
  end

  #
  # Received a message to scrape and count of tweets specified by the user is not satisfied.
  #
  def handle_info({:scrape, {username, count, last_tweet_id}}, state) when count > 0 do
    # TODO: Handle error case here.
    %TwitterFeed.Feed{
      last_tweet_retrieved: last_tweet_id_new,
      more_tweets_exist: more_tweets?,
      tweets: tweets} = TwitterFeed.get_tweets(username, last_tweet_id)

    # Insert the tweets into database.
    insert_into_database(tweets, count)

    # Decrement count by number of tweets scrapped in current scrape iteration.
    count = count - length(tweets)

    # Check if token is available from rate_limiter agent.
    token_available? = RateLimiter.token_available?()

    # start next_scrape iteration.
    next_scrape?(username, last_tweet_id_new, count, more_tweets?, token_available?)
    {:noreply, state}
  end

  #
  # Received a message to reset the number of tokens in rate_limiter agent, after
  # the timeout.
  #
  def handle_info(:reset_rate_limiter, state) do
    IO.puts("Sending message to reset tokens")
    RateLimiter.reset_tokens()
    reset_rate_limiter()
    {:noreply, state}
  end

  #
  # Reset the tokens in rate_limiter agent. Process.send_after/3 sends a message
  # to self(after timeout minutes) to form a loop to reset the tokens periodically.
  #
  defp reset_rate_limiter() do
    timeout = Application.get_env(:twitter_scrapper, :rate_limiter)[:timeout]
    Process.send_after(self(), :reset_rate_limiter, :timer.minutes(timeout))
  end

  #
  # Tweets are inserted into database. Tweets list is sliced as sometimes
  # length(tweets) can be greater than count, slice helps us to store only the
  # user desired tweets.
  #
  defp insert_into_database(tweets, count) do
    tweets
    |> Enum.slice(@zero_index, count)
    |> Enum.map(fn tweet -> translate_tweet_to_db_schema(tweet) end)
    |> Enum.each(fn tweet -> TwitterScrapper.Repo.insert(tweet) end)
  end

  #
  # No more tokens granted from rate_limiter, the tokens have been exhausted.
  #
  defp next_scrape?(_username, _last_tweet_id, _count, _more_tweets?, false = _token_available?) do
    IO.puts("Ran out of tokens")
  end

  #
  # No more tweets to scrape, no more twwets found on twitter by the specified author.
  #
  defp next_scrape?(_username, _last_tweet_id, _count, false = _more_tweets?, _token_available?) do
    IO.puts("Reached end of tweets")
  end

  #
  # Start next_scrape iteration. There are more tweets to scrape and tokens are
  # also available
  #
  defp next_scrape?(username, last_tweet_id, count, true = _more_tweets?, true = _token_available?) do
    Process.send(self(), {:scrape, {username, count, last_tweet_id}}, [])
  end

  #
  # The Tweet are parsing are of the format: %TwitterFeed.Tweet{}, need to be
  # converted into %%TwitterScrapper.Tweet{} before inserting into database.
  #
  defp translate_tweet_to_db_schema(%TwitterFeed.Tweet{
      likes: likes,
      replies: replies,
      retweets_number: retweets,
      text_summary: tweet_text,
      timestamp: timestamp,
      user_name: author}) do

    %TwitterScrapper.Tweet{
      author_name: author,
      date_time_stamp: timestamp,
      likes: likes,
      replies: replies,
      retweets: retweets,
      tweet_text: tweet_text
    }

  end
end
