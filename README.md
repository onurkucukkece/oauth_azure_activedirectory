# Oauth Azure Activedirectory

**TODO: Add description**

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

```
config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: System.get_env("AZURE_CLIENT_ID"),
  client_secret: System.get_env("AZURE_CLIENT_SECRET"),
  tenant: System.get_env("AZURE_TENANT"),
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/oauth_azure_activedirectory](https://hexdocs.pm/oauth_azure_activedirectory).

