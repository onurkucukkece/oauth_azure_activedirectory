# Oauth Azure Activedirectory

https://hex.pm/packages/oauth_azure_activedirectory

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oauth_azure_activedirectory` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oauth_azure_activedirectory, "~> 0.1.0-beta"}
  ]
end
```
## Configuration

```elixir
config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: System.get_env("AZURE_CLIENT_ID"),
  client_secret: System.get_env("AZURE_CLIENT_SECRET"),
  tenant: System.get_env("AZURE_TENANT"),
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback" # Will get rid of this before release
```

### Usage

```elixir
# Add your routes, i.e.

scope "/auth", MyAppWeb do
  pipe_through :browser

  get "/:provider", AuthController, :authorize
  post "/:provider/callback", AuthController, :callback
end

# Adjust your controller actions for authorization and the callback

defmodule MyAppWeb.AuthController do
  use MyAppWeb, :controller

  alias MyApp.User
  alias OauthAzureActivedirectory.Client

  def authorize(conn, _params) do
    redirect conn, external: Client.authorize_url!(_params)
  end

  def callback(conn, _params) do
    {:ok, jwt} = Client.process_callback!(conn)
    case User.find_or_create(jwt) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "Successfully authenticated.")
        |> put_session(:current_user, user)
        |> Guardian.Plug.sign_in(user) # if you are using Guardian
        |> redirect(to: "/")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end

# Add a method to User model to process the data in JWT
def find_or_create(jwt) do
  email = jwt[:upn]
  query = from u in User, where: u.email == ^email
  case Repo.one(query) do
    user -> {:ok, user}
    [] -> create_user(%{email: email, password: SecureRandom.base64(8)})
  end
end
```
### Information

```elixir
{:ok, jwt} = Client.process_callback!(conn)
# On a successful callback, jwt variable will return something like below.

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/oauth_azure_activedirectory](https://hexdocs.pm/oauth_azure_activedirectory).

