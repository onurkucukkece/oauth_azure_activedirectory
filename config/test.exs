# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :oauth_azure_activedirectory, OauthAzureActivedirectory.Client,
  client_id: "58b6472d-deb6-4062-b0fc-88fb4972491e",
  tenant: "042153ca-e0a2-45ba-b335-9e9a06632174",
  redirect_uri: "http://localhost:4000/auth/azureactivedirectory/callback"