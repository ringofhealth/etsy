defmodule Etsy.Env do
  @moduledoc """
  Helper module to get environment variables from the host application.

  Most options can be set using either a System environment variable or an elixir configuration.
  """

  @app :etsy
  @defaults [
    scopes: ~w(profile_r email_r transactions_r feedback_r),
    max_connections: 50,
    timeout: 150_000,
    consumer_key: "",
    consumer_secret: "",
    callback: "oob"
  ]

  @doc """
  Get the current library version.
  """
  @spec library_version() :: String.t()
  def library_version do
    @app
    |> Application.spec()
    |> Keyword.get(:vsn)
    |> to_string()
  end

  @doc """
  Set API scopes.

  default value: `["profile_r", "email_r", "transactions_r", "feedback_r"]`

  Set using System env or elixir config:

  `ETSY_SCOPES="profile_r;email_r;transactions_r;feedback_r"`

  `config :etsy, scopes: ~w(profile_r email_r transactions_r feedback_r)`
  """
  @spec scopes() :: list()
  def scopes do
    "ETSY_SCOPES"
    |> env(:scopes)
    |> List.wrap()
    |> Enum.join(" ")
  end

  def callback do
    "ETSY_CALLBACK"
    |> env(:callback)
  end

  def timeout do
    "ETSY_TIMEOUT"
    |> env(:timeout)
  end

  def consumer_key do
    "ETSY_CONSUMER_KEY"
    |> env(:consumer_key)
  end

  def consumer_secret do
    "ETSY_CONSUMER_SECRET"
    |> env(:consumer_secret)
  end

  def max_connections do
    "ETSY_MAX_CONNECTIONS"
    |> env(:max_connections)
    |> to_number(@defaults[:max_connections])
  end

  defp env(string, key, default \\ nil) do
    (System.get_env(string) ||
       Application.get_env(@app, key, Keyword.get(@defaults, key, default)))
    |> parse()
  end

  defp parse(string) when is_bitstring(string) do
    if string =~ ";" do
      string
      |> String.split(";")
      |> Enum.map(&String.trim/1)
    else
      string
    end
  end

  defp parse(list) when is_list(list), do: Enum.map(list, &parse/1)
  defp parse(atom) when is_atom(atom), do: atom
  defp parse(number) when is_number(number), do: number
  defp parse(nil), do: nil
  defp parse({key, value}), do: {key, value}
  defp parse(_), do: nil

  defp to_number(value, _) when is_number(value), do: value

  defp to_number(value, default) when is_bitstring(value) do
    String.to_integer(value)
  rescue
    _ -> default
  end

  defp to_number(_, default), do: default

  #  defp to_boolean(boolean) when is_boolean(boolean), do: boolean
  #  defp to_boolean("true"), do: true
  #  defp to_boolean(_), do: false
end
