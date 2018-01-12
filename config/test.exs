# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: "client_id",
  client_secret: "client_secret",
  tenant: "tenant",
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback"