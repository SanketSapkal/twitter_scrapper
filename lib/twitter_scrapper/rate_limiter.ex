defmodule TwitterScrapper.RateLimiter do
  @moduledoc """
  Token based rate limiter implemented using Elixir Agent. Has functions for
  getting a token and resetting the tokens available.

  Twitter also has a rate limiter. Due to lack of knowledge about twitter's
  rate limiter for html web scrappers, this rate limiter has been implemented on
  top of scrapper to avoid blacklisting by twitter.
  """
  use Agent

  def start_link(_) do
    tokens = Application.get_env(:twitter_scrapper, :rate_limiter)[:tokens_per_window]
    Agent.start_link(fn -> tokens end, name: __MODULE__)
  end

  @doc """
  Get a token from rate limiter if available. The tokens are get first,
    - tokens are available(or num of tokens > 0): return true to the calling process, decrement the token count.
    - no tokens are available: return false to the calling process.

  ## Examples:
      :iex> TwitterScrapper.RateLimiter.token_available?()
      true
  """
  @spec token_available?() :: boolean()
  def token_available?() do
    Agent.get(__MODULE__, fn tokens -> tokens end)
    |> decrement_tokens
  end

  @doc """
  Reset the tokens, to initial count.

  ## Examples:
      :iex> TwitterScrapper.RateLimiter.reset_tokens()
      :ok
  """
  @spec reset_tokens() :: :ok
  def reset_tokens() do
    IO.puts("Resetting tokens.....")
    tokens = Application.get_env(:twitter_scrapper, :rate_limiter)[:tokens_per_window]
    Agent.update(__MODULE__, fn _state -> tokens end)
  end

  #
  # No operation is done here and false is returned as tokens are not available.
  #
  defp decrement_tokens(tokens) when tokens <= 0 do
    false
  end

  #
  # Decrement the token count by 1 and return true. Here true signifies a token
  # can be given to the calling process.
  #
  defp decrement_tokens(_tokens) do
    Agent.update(__MODULE__, &(&1 - 1))
    true
  end
end
