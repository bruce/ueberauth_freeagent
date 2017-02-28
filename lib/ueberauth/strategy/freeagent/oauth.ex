defmodule Ueberauth.Strategy.FreeAgent.OAuth do
  @moduledoc """
  An implementation of OAuth2 for FreeAgent, using the v2 API.

  See `Ueberauth.Strategy.FreeAgent` for configuration details.
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.freeagent.com/v2",
    authorize_url: "https://api.freeagent.com/v2/approve_app",
    token_url: "https://api.freeagent.com/v2/token_endpoint",
  ]

  @sandbox_defaults [
    strategy: __MODULE__,
    site: "https://api.sandbox.freeagent.com/v2",
    authorize_url: "https://api.sandbox.freeagent.com/v2/approve_app",
    token_url: "https://api.sandbox.freeagent.com/v2/token_endpoint",
  ]

  @use_sandbox_defaults [
    true: @sandbox_defaults,
    false: @defaults
  ]

  @doc """
  Construct a client for requests to FreeAgent.

  Optionally include any OAuth2 options here to be merged with the defaults.

  These options are only useful for usage outside the normal callback phase of Ueberauth.

  ## Examples

  ```
  profile =
    Ueberauth.Strategy.FreeAgent.OAuth.client(token: "THE_ACCESS_TOKEN")
    |> OAuth2.Client.get("/users/me")
  ```
  """
  def client(opts \\ []) do
    defaults = @use_sandbox_defaults[Application.get_env(:ueberauth_freeagent, :sandbox, false)]
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.FreeAgent.OAuth)
    client_opts =
      defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    client = OAuth2.Client.new(client_opts)
    client
    # FreeAgent doesn't seem to currently like basic auth
    |> put_param("client_id", client.client_id())
    |> put_param("client_secret", client.client_secret())
  end

  @doc false
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc false
  def get_token!(params \\ [], options \\ []) do
    headers        = Keyword.get(options, :headers, [])
    options        = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client         = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  @doc false
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @doc false
  def get_token(client, params, headers) do
    client
    |> put_param("grant_type", "authorization_code")
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
