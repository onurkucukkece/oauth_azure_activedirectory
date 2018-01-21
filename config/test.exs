# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: System.get_env("CLINT_ID"),
  tenant: System.get_env("TENANT_ID"),
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback"