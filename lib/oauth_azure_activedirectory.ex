defmodule OauthAzureActivedirectory do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.
  """

  @after_compile __MODULE__
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

  def __after_compile__(_env, _bytecode) do
    with {ret, 0} <- System.cmd("echo", ["Warning: oauth_azure_activedirectory v1.2.2 includes breaking changes that may affect your app. See the CHANGELOG for details.
"]) do
      IO.puts(ret)
    end
  end
end
