defmodule Etsy.Credentials do
  @moduledoc """
  Struct to hold both temporary credentials during the Oauth 1 handshake and User's oauth credentials
  """
  @type t :: %__MODULE__{token: String.t(), secret: String.t()}

  defstruct token: "", secret: ""

  @spec new(token: String.t(), secret: String.t()) :: t()
  def new(token: token, secret: secret), do: %__MODULE__{token: token, secret: secret}

  @spec new(String.t(), String.t()) :: t()
  def new(token, secret), do: new(token: token, secret: secret)
end
