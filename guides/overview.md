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
`Etsy.authorization_url/0` and getting the user to visit the generated login URL.
When the user authorizes your application the `oauth_token` and `oauth_verifier` will provided to you 
as query params to your callback URL. Pass the `oauth_verifier` to the `Etsy.access_token/1` function. 
Here is an example of a Phoenix controller doing this.

```elixir
# Generate authorization URL and get user to visit the login URL
Etsy.authorization_url()
# =>
{:ok,
 "https://www.etsy.com/oauth/signin?oauth_consumer_key=REDACTED&oauth_token=REDACTED&service=v2_prod&oauth_token=REDACTED&oauth_token_secret=REDACTED&oauth_callback_confirmed=true&oauth_consumer_key=REDACTED&oauth_callback=https://sdc-encased-backend.ngrok.io/oauth/etsy"}
```

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
using `Etsy.TokenStore.update/1`.

```elixir
# get oauth stored token and secret from db
Etsy.TokenStore.update([token: "66ec3b28686...", token_secret: "1e51..."])
```


After you set the oauth token secret you can call any `Etsy` functions to hit the [etsy's api](https://www.etsy.com/developers/documentation/reference/listing)

## Examples
```elixir
Etsy.scopes()                                               # Get current access's token scopes
Etsy.get("/v2/users/__SELF__")                              # Get user info
{:ok, results} = Etsy.get("/users/__SELF__/shops")          # Get user's shops

shop_id = 
  results 
  |> Map.get("results") 
  |> hd() 
  |> Map.get("shop_id")

Etsy.get("/shops/#{shop_id}/listings/active")               # Get shops' active listings
Etsy.get("/users/__SELF__/shipping/templates")              # Get User's shipping templates

 
shipping_template_id = 103831012072
Etsy.delete("/shipping/templates/#{shipping_template_id}")  # Delete shipping template


{:ok, result} = Etsy.get("/countries/iso/US")               # Get Country info

country_id = 
  result 
  |> Map.get("results") 
  |> hd() 
  |> Map.get("country_id")

{:ok, result} = Etsy.post("/shipping/templates", [
    {"title", "test-shipping-template"},
    {"origin_country_id", country_id},
    {"primary_cost", "0.53"},
    {"secondary_cost", "0.0"},
  ])

shipping_template_id = 
  result 
  |> Map.get("results") 
  |> hd() 
  |> Map.get("shipping_template_id")

# Create listing
Etsy.post("/listings", [
    {"quantity", "1"},
    {"title", "test-api-listing"},
    {"shipping_template_id", shipping_template_id},
    {"description", "test api created listing"},
    {"price", "0.50"},
    {"taxonomy_id", "1633"},
    {"who_made", "i_did"},
    {"is_supply", "false"},
    {"when_made", "made_to_order"},
  ])


# Update Listing
listing_id = 851388163
products = """
[{"is_deleted":0,"offerings":[{"is_deleted":0,"is_enabled":1,"price":{"amount":50,"currency_code":"USD","currency_formatted_long":"$0.60 USD","currency_formatted_raw":"0.60","currency_formatted_short":"$0.60","divisor":100},"quantity":1}],"property_values":[],"sku":""}]
"""
Etsy.put("/listings/#{listing_id}/inventory", [
  {"listing_id", listing_id},
  {"products", products}
])
```

 