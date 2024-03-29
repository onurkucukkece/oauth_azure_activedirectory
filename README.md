# Oauth Azure Activedirectory

Omniauth client for Azure Active Directory using [Microsoft identity hybrid authorization code flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow#request-an-id-token-as-well-or-hybrid-flow)

https://hex.pm/packages/oauth_azure_activedirectory

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/onurkucukkece/oauth_azure_activedirectory/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/onurkucukkece/oauth_azure_activedirectory/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/onurkucukkece/oauth_azure_activedirectory/badge.svg)](https://coveralls.io/github/onurkucukkece/oauth_azure_activedirectory)
[![Hex.pm version](https://img.shields.io/hexpm/v/oauth_azure_activedirectory.svg?style=flat-square)](https://hex.pm/packages/oauth_azure_activedirectory)
[![Hex.pm downloads](https://img.shields.io/hexpm/dt/oauth_azure_activedirectory.svg)](https://hex.pm/packages/oauth_azure_activedirectory)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oauth_azure_activedirectory` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oauth_azure_activedirectory, "~> 1.2"}
  ]
end
```
## Configuration

```elixir
config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: System.get_env("AZURE_CLIENT_ID"),
  client_secret: System.get_env("AZURE_CLIENT_SECRET"),
  tenant: System.get_env("AZURE_TENANT"),
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback",
  scope: "openid email profile",
  logout_redirect_url: "http://localhost:4000/users/logout"
```

### Azure AD
Enable `ID tokens` for Implicit grant and hybrid flows in authentication settings of your Azure AD application.

## Usage

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
    redirect conn, external: Client.authorize_url!()
    # Alternatively, you can pass a custom state to identify multiple requests/callbacks
    # redirect conn, external: Client.authorize_url!("custom-state")
  end

  def callback(conn, _params) do
    {:ok, payload} = Client.callback_params(conn)
    email = payload["email"]
    case User.find_or_create(email) do
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
def find_or_create(email) do
  query = from u in User, where: u.email == ^email
  case Repo.all(query) do
    [user] -> {:ok, user}
    [] -> create_user(%{email: email, password: SecureRandom.base64(16)})
  end
end

```

### Signing users out
```elixir
OauthAzureActivedirectory.Client.logout_url()
# will return Azure end session URL
```
**⚠️ In some Chrome versions, users are not redirected to `logout_redirect_url` after signing out from their Microsoft account.**

To make sure that the users end their session in your application, you can do one of the following

- Set a Front-channel logout URL in your Azure application.

  Once users sign out from their Microsoft account, a silent request will be sent to logout URL with a `sid` attribute in query parameters which matches the `session_state` that was sent in callback payload. 
- Add `logout_hint` to logout URL. That will sign users out from their Microsoft account without allowing them to choose which user to logout. This somehow fixes broken redirection. To do that
  1. Add `login_hint` optional ID claim to your Azure application as descibed [here](https://learn.microsoft.com/en-us/azure/active-directory/develop/optional-claims). This will add `login_hint` attribute to callback payload.
  2. Store the hint along with user session
  3. Pass it to `OauthAzureActivedirectory.Client.logout_url(logout_hint)` function 

## Information

```elixir

Client.authorize_url!()
# will generate a url similar to 
# https://login.microsoftonline.com/9b9eff0c-3e5t-1q2w-3e4r-fe98afcd0299/oauth2/v2.0/authorize?client_id=984ebc2a-4ft5-8ea2-0000-59e43ccd614e&nonce=e22d15fa-853f-4d6a-9215-e2a206f48581&provider=azureactivedirectory&redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fazureactivedirectory%2Fcallback&response_mode=form_post&response_type=code+id_token

{:ok, payload} = Client.callback_params(conn)
# On a successful callback, jwt variable will return something like below.

%{
  exp: 1515604135,
  family_name: "Allen",
  given_name: "Otis",
  name: "Otis Allen",
  nonce: "e22d15fa-853f-4d6a-9215-e2a206f48581",
  email: "otis.allen@company.com",
  uti: "heXGJdeefedrzEuc1bQNAA",
  ver: "2.0"
  ...
}

# For all attributes, see claims_supported in https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration

```

## Useful links
[Azure AD token reference](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-token-and-claims)

[Microsoft OpenID discovery document.](https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration)

[Trusted CA certificates for Azure Cloud Services](https://docs.microsoft.com/en-us/azure/security/fundamentals/tls-certificate-changes)
