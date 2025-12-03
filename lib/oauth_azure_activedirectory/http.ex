defmodule OauthAzureActivedirectory.Http do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.Http
  """

  @doc """
  Make an HTTP GET request and verify peer Azure TLS certificate

  """
  def request(url) do
    cacert = :code.priv_dir(:oauth_azure_activedirectory) ++ ~c"/DigiCertGlobalRootCA.crt.pem" |> File.read!
    cacerts = :public_key.pem_decode(cacert) |> Enum.map(fn {_, der, _} -> der end)

    :httpc.set_options(socket_opts: [verify: :verify_peer, cacerts: cacerts])

    case :httpc.request(:get, {to_charlist(url), []}, [], []) do
      {:ok, response} ->
        {{_, 200, ~c"OK"}, _headers, body} = response
        body
      {:error} -> false
    end
  end
end
