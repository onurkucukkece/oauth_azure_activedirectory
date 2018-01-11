# Oauth Azure Activedirectory

Omniauth authentication for Azure Active Directory using JWT.

https://hex.pm/packages/oauth_azure_activedirectory

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oauth_azure_activedirectory` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oauth_azure_activedirectory, "~> 0.1.0-beta2"}
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
  case Repo.all(query) do
    [user] -> {:ok, user}
    [] -> create_user(%{email: email, password: SecureRandom.base64(8)})
  end
end
```
### Information

```elixir

Client.authorize_url!(_params)
# will generate a url similar to 
# https://login.microsoftonline.com/9b9eff0c-3e5t-1q2w-3e4r-fe98afcd0299/oauth2/authorize?client_id=984ebc2a-4ft5-8ea2-0000-59e43ccd614e&nonce=e22d15fa-853f-4d6a-9215-e2a206f48581&provider=azureactivedirectory&redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fazureactivedirectory%2Fcallback&response_mode=form_post&response_type=code+id_token

{:ok, jwt} = Client.process_callback!(conn)
# On a successful callback, jwt variable will return something like below.

%{aio: "ASQA2/5GDSAjMRuLsckD5QfrTG6aYZvsKvIZD2py9OqC8po/LQ6QA=", amr: ["pwd"],
  aud: "984ebc2a-4ft5-8ea2-0000-59e43ccd614e", c_hash: "ljiphg5fTpgfreh65owaQ",
  exp: 1515604135, family_name: "Allen", given_name: "Otis",
  iat: 1515600235, ipaddr: "92.7.119.241",
  iss: "https://sts.windows.net/9b9eff0c-3e5t-1q2w-3e4r-fe98afcd0299/",
  name: "Otis Allen", nbf: 1515600235,
  nonce: "e22d15fa-853f-4d6a-9215-e2a206f48581",
  oid: "0110c209-b543-4aac-b156-7f406a4f98d0",
  sub: "d70UoIpU-qSewpk_SI0MGktghymbNAq-klrsdEhIWfQ",
  tid: "9b9eff0c-3e5t-1q2w-3e4r-fe98afcd0299",
  unique_name: "otis.allen@company.com",
  upn: "otis.allen@company.com", uti: "heXGJdeefedrzEuc1bQNAA",
  ver: "1.0"}

```

### Useful links
[Azure AD token reference](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-token-and-claims)

You can decode your id_token at http://jwt.ms/

[Microsoft OpenID discovery document.](https://login.microsoftonline.com/common/.well-known/openid-configuration)

[Microsoft Discovery Keys](https://login.microsoftonline.com/common/discovery/keys)
