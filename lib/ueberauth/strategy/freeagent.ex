defmodule Ueberauth.Strategy.FreeAgent do
  @moduledoc """
  FreeAgent OAuth2 strategy for Überauth.

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

  For information on how to configure Phoenix to use this strategy, see the [README](./extra-readme.html)

  """
  use Ueberauth.Strategy, uid_field: :email,
                          oauth2_module: Ueberauth.Strategy.FreeAgent.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the FreeAgent authentication page.

  You can include a `state` param that FreeAgent will return to you.
  """
  def handle_request!(conn) do
    opts = [redirect_uri: callback_url(conn), response_type: "code"]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from FreeAgent. When there is a failure from FreeAgent the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from FreeAgent is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code, redirect_uri: callback_url(conn)]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw freeagent response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:freeagent_user, nil)
    |> put_private(:freeagent_token, nil)
  end

  @doc """
  Fetches the uid field from the FreeAgent response.
  This defaults to the option `uid_field` which in-turn defaults to `email`
  """
  def uid(conn) do
    user =
      conn
      |> option(:uid_field)
      |> to_string
    conn.private.freeagent_user[user]
  end

  @doc """
  Includes the credentials from the FreeAgent response.
  """
  def credentials(conn) do
    token        = conn.private.freeagent_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.freeagent_user

    %Info{
      name: user["first_name"] <> " " <> user["last_name"],
      first_name: user["first_name"],
      last_name: user["last_name"],
      email: user["email"],
      description: user["role"],
      urls: %{
        url: user["url"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the freeagent callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.freeagent_token,
        user: conn.private.freeagent_user
      }
    }
  end

  @spec fetch_user(conn :: Plug.Conn.t, token :: binary) :: Plug.Conn.t
  defp fetch_user(conn, token) do
    conn = put_private(conn, :freeagent_token, token)

    case profile(token) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: payload}} when status_code in 200..399 ->
        case payload do
          %{"user" => user} ->
            put_private(conn, :freeagent_user, user)
          _ ->
            set_errors!(conn, [error("OAuth2", "could not find profile")])
        end
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  # Attempt to retrieve the user profile
  @spec profile(token :: binary) :: {:ok, OAuth2.Response.t} | {:error, OAuth2.Error.t}
  defp profile(token) do
    Ueberauth.Strategy.FreeAgent.OAuth.client(token: token)
    |> OAuth2.Client.get("/users/me")
  end

  # Extract an option from the connection
  @spec option(conn :: Plug.Conn.t, key :: atom) :: any
  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
