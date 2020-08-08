# Etsy 

## Setup

Add `:etsy` to your mix.exs file

```elixir
def deps do
  [
    {:etsy, "~> 1.0"}
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
`Etsy.authorization_url/0` and getting the user to visit the generated login URL. `Etsy.authorization_url/0` also
returns temporary credentials that you will need to store to be used after the user authorizes your application.

When the user authorizes your application, they will be redirected to your callback URL and 
the `oauth_token` and `oauth_verifier` will provided to you as query params. 
Pass the temporary credentials from step 1 and the `oauth_verifier` to the `Etsy.access_token/2`. 

Here is an example of calling `Etsy.authorization_url/0`
```elixir
# Generate authorization URL and get user to visit the login URL
iex(1)> Etsy.authorization_url()
{:ok,
 {%Etsy.Credentials{
    secret: "2935e1fb1a",
    token: "e9a33f99be6eac893e6e3771e4c429"
  },
  "https://www.etsy.com/oauth/signin?oauth_consumer_key=REDACTED&oauth_token=e9a33f99be6eac893e6e3771e4c429&service=v2_prod&oauth_token=e9a33f99be6eac893e6e3771e4c429&oauth_token_secret=2935e1fb1a&oauth_callback_confirmed=true&oauth_consumer_key=REDACTED&oauth_callback=https://sdc-encased-backend.ngrok.io/oauth/etsy"}}
```

Here is an example of a Phoenix controller doing the whole Auth flow and using an ets to store the temporary credentials.
```elixir
# ...
    alias Etsy.Credentials
    require Logger
    
    @ets_table :etsy
    
    def init(conn, _) do
      # in your application.ex create an ets table to store temporary auth credentials
      # :ets.new(:etsy, [:set, :public, :named_table])
    
      # Generate an authorization url
      case Etsy.authorization_url() do
        {:ok, {%Credentials{token: token} = credentials, url}} ->
          # Store temporary credentials in the ets table using the temporary token as the key
          :ets.insert(@ets_table, {token, credentials})
    
          # Send user to authorization url
          redirect(conn, external: url)
    
        error ->
          Logger.error("Error generating authorization url. error: #{inspect(error)}")
          :error
      end
    end
    
    def callback(conn, %{"oauth_token" => oauth_token, "oauth_verifier" => oauth_verifier}) do
      # Fetch temporary credentials from ets using the token
      case :ets.lookup(@ets_table, oauth_token) do
        [] ->
          Logger.error("No credentials found in ets. Make sure you imitated the oauth flow.")
          send_resp(conn, 400, "")
    
        [{^oauth_token, credentials}] ->
          case Etsy.access_token(credentials, oauth_verifier) do
            {:ok, %Credentials{token: token, secret: secret}} ->
              # Here you should store the User credentials in your database
    
              # Example using these credentials to call the Etsy api
              [token: token, secret: secret]
              |> Credentials.new()
              |> Etsy.scopes()
              |> IO.inspect()
    
              json(conn, "ok")
    
            _ ->
              send_resp(conn, 400, "")
          end
    
        error ->
          Logger.error("Error looking up credentials in ets. error: #{inspect(error)}")
          send_resp(conn, 400, "")
      end
    end
```
`Etsy.access_token/2` will finish the hand shake and return the user's oauth token and secret which can be used for
all subsequent api calls.

If the user has already authorized your application, and you have their oauth token and oauth token secret stored,
just manually create an `Etsy.Credentials` struct and use that to make api calls.

```elixir
# get oauth stored token and secret from db
[token: "66ec3b28686...", secret: "1e51..."]
|> Etsy.Credentials.new()
|> Etsy.get("/users/__SELF__")
```


After you create the `Etsy.Credentials` you can use them to call any `Etsy` functions to hit the [etsy's api](https://www.etsy.com/developers/documentation/reference/listing)

## Examples
```elixir
creds = Etsy.Credentials.new([token: "66ec3b28686...", secret: "1e51..."])
Etsy.scopes(creds)                                                  # Get current access's token scopes
Etsy.get(creds, "/users/__SELF__")                                  # Get user info
{:ok, results} = Etsy.get(creds, "/users/__SELF__/shops")           # Get user's shops

shop_id = 
  results 
  |> Map.get("results") 
  |> hd() 
  |> Map.get("shop_id")

Etsy.get(creds, "/shops/#{shop_id}/listings/active")               # Get shops' active listings
Etsy.get(creds, "/users/__SELF__/shipping/templates")              # Get User's shipping templates

 
shipping_template_id = 103831012072
Etsy.delete(creds, "/shipping/templates/#{shipping_template_id}")  # Delete shipping template


{:ok, result} = Etsy.get(creds, "/countries/iso/US")               # Get Country info

country_id = 
  result 
  |> Map.get("results") 
  |> hd() 
  |> Map.get("country_id")

{:ok, result} = Etsy.post(creds, "/shipping/templates", [
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
Etsy.post(creds, "/listings", [
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
Etsy.put(creds, "/listings/#{listing_id}/inventory", [
  {"listing_id", listing_id},
  {"products", products}
])
```

 