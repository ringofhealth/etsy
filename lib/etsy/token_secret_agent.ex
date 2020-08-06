defmodule Etsy.TokenSecretAgent do
  @moduledoc """
  Agent to store token secret
  """

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def set(value) do
    Agent.update(__MODULE__, fn _ -> value end)
  end
end
