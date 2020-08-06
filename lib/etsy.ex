defmodule Etsy do
  @moduledoc """
  Main Etsy API
  """

  alias Etsy.HTTP

  def authorization_url, do: HTTP.authorization_url()

  def access_token(oauth_token, oauth_verifier),
    do: HTTP.access_token(oauth_token, oauth_verifier)
end
