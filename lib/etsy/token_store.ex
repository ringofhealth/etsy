defmodule Etsy.TokenStore do
  @moduledoc """
  Agent to store token secret
  """

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [token: nil, token_secret: nil] end, name: __MODULE__)
  end

  def token, do: Agent.get(__MODULE__, fn state -> Keyword.get(state, :token) end)
  def token_secret, do: Agent.get(__MODULE__, fn state -> Keyword.get(state, :token_secret) end)

  def update(token: token, token_secret: token_secret) do
    update_token(token)
    update_token_secret(token_secret)
  end

  def update_token(token) do
    Agent.update(__MODULE__, fn state -> Keyword.put(state, :token, token) end)
  end

  def update_token_secret(secret) do
    Agent.update(__MODULE__, fn state -> Keyword.put(state, :token_secret, secret) end)
  end

  def clear, do: Agent.update(__MODULE__, fn _ -> [] end)
end
