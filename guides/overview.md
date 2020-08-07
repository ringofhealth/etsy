# Etsy 

## Setup

Add `:etsy` to your mix.exs file

```elixir
def deps do
  [
    {:etsy, "~> 0.1"}
  ]
end
```

## Configure
You can set configuration using System environment variables 
or using elixir config.

The `:consumer_key` and `:consumer_secret` are the only required configs, but you 
will most likely also want to also set the `:scopes` and `:callback` options.

```elixir
config :etsy,
  consumer_key: "xatfgj4rbod2al11h1j5ws6j",
  consumer_secret: "a55ibdr2ee",
  scopes: ~w(profile_r email_r transactions_r feedback_r),
  callback: "https://sdc-encased-backend.ngrok.io/oauth/etsy"
```

See the [env.example](https://github.com/spencerdcarlson/etsy/blob/master/env.example) on 
how to set these configs using System environment variables.

## Usage

Initiate the Oauth v1 flow by calling
`Etsy.authorization_url/0` and getting the user to visit the generated login url.
When the user authorizes your application the `oauth_token` and `oauth_verifier` will provided to you 
as query params to your callback url. Pass the `oauth_verifier` to the `Etsy.access_token/1` function. 
Here is an example of a Phoenix controller doing this.

```elixir
# ...
def callback(conn, %{"oauth_token" => _, "oauth_verifier" => oauth_verifier}) do
  case Etsy.access_token(oauth_verifier) do
    {:ok, %{"oauth_token" => oauth_token, "oauth_token_secret" => oauth_token_secret}} ->
      # Save oauth_token and oauth_token_secret to db
      json(conn, "ok")

    _ ->
      send_resp(conn, 400, "")
  end
end
```
`Etsy.access_token/1` will finish the hand shake and save the oauth token and oauth token secret 
in Etsy's application state. See the `Etsy.TokenStore` module for more details.

If the user has already authorized your application, and you have their oauth token and oauth token secret stored,
you can skip the Oauth flow by setting the token and secret 
using `Etsy.TokenStore.update_token/1` and `Etsy.TokenStore.update_token_secret/1` respectively.

Once the oauth token and oauth secret are set you can call any `Etsy` functions to hit the etsy's api

```elixir
# get oauth stored token and secret from db
Etsy.TokenStore.update_token("66ec3b28686...")
Etsy.TokenStore.update_token_secret("1e51...")
Etsy.call(:get, "/v2/users/__SELF__")
Etsy.call(:get, "/shops/:shop_id/listings/draft?shop_id=SDCEncasedDevShop")
Etsy.call(:get, "/users/__SELF__/shipping/templates")

# Create listing
Etsy.call(:post, "/listings", [
    {"quantity", "1"},
    {"title", "test-api-listing"},
    {"description", "test api created listing"},
    {"price", "0.50"},
    {"taxonomy_id", "1633"},
    {"who_made", "i_did"},
    {"is_supply", "false"},
    {"when_made", "made_to_order"},
  ])
```

 