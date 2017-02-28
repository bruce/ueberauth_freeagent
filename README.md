# Überauth FreeAgent

FreeAgent OAuth2 strategy for Überauth.

## Installation

Setup your application at the [FreeAgent Developer](https://dev.freeagent.com/) site.

Add `:ueberauth_freeagent` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ueberauth_freeagent, "~> 0.1"}]
end
```

If using Elixir < 1.4, make sure to add the strategy to your applications:

```elixir
def application do
  [applications: [:ueberauth_freeagent]]
end
```

## Configuration

Add `freeagent` to your Überauth configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    freeagent: {Ueberauth.Strategy.FreeAgent, []}
  ]
```

Update your provider configuration, setting your `client_id` and `client_secret`:

```elixir
config :ueberauth, Ueberauth.Strategy.FreeAgent.OAuth,
  client_id: System.get_env("FREEAGENT_CLIENT_ID"),
  client_secret: System.get_env("FREEAGENT_CLIENT_SECRET")
```

 **IMPORTANT**: To use the FreeAgent sandbox API, set `sandbox` to `true` for the `:ueberauth_freeagent` application:

```elixir
config :ueberauth_freeagent,
  sandbox: true
```

This will automatically configure the correct URLs.

## OAuth2 Flow

Create a controller to implement callbacks to deal with `Ueberauth.Auth` and
`Ueberauth.Failure` responses. For an example implementation see the [Überauth
Example](https://freeagent.com/ueberauth/ueberauth_example) application.

Make sure you include the Überauth plug in your router:

```elixir
pipeline :auth do
  plug Ueberauth
end
```

Configure the request and callback routes, making sure to use pipeline:

```elixir
scope "/auth", MyApp do
  pipe_through [:auth, :browser]

  get "/:provider", AuthController, :request
  get "/:provider/callback", AuthController, :callback
end
```

### Calling

Depending on the configured url you can initial the request through:

    /auth/freeagent

### Authentication State

You may want to look at [Guardian](https://github.com/ueberauth/guardian) (or
something like it) to manage serializing authentication information across
requests.

## Using the Client

You can use the OAuth-configured client to access the FreeAgent API once you're
authenticated and have a token handy.

See `Ueberauth.Strategy.FreeAgent.OAuth.client/1` for more information.

## License

Please see [LICENSE](https://freeagent.com/ueberauth/ueberauth_freeagent/blob/master/LICENSE) for license details.
