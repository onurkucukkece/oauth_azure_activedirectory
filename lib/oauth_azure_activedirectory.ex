defmodule OauthAzureActivedirectory do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.
  """

  @base_url URI.parse("https://login.microsoftonline.com")

  @doc """
  Return configuration set.
  """
  def config do
    Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
  end

  def base_url, do: @base_url

  def request_url do
    %URI{
      authority: @base_url.authority,
      host: @base_url.host,
      path: "/#{config()[:tenant]}/oauth2/v2.0",
      port: @base_url.port,
      scheme: @base_url.scheme
    }
  end
end
