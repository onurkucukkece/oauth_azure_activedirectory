# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: "the client id",
  tenant: "tenant",
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback"