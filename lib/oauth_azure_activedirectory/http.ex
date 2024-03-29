defmodule OauthAzureActivedirectory.Http do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.Http
  """

  @doc """
  Make an HTTP GET request and verify peer Azure TLS certificate

  """
  def request(url) do
    cacert =  :code.priv_dir(:oauth_azure_activedirectory) ++ '/DigiCertGlobalRootCA.crt.pem'
    :httpc.set_options(socket_opts: [verify: :verify_peer, cacertfile: cacert])

    case :httpc.request(:get, {to_charlist(url), []}, [], []) do
      {:ok, response} -> 
        {{_, 200, 'OK'}, _headers, body} = response
        body
      {:error} -> false
    end
  end
end
