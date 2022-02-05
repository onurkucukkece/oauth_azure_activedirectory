defmodule OauthAzureActivedirectory.Response do
  def validate(claims, code) do    
    header = Enum.at(claims, 0) |> Base.url_decode64!(padding: false) |> JSON.decode!
    payload = Enum.at(claims, 1) |> Base.url_decode64!(padding: false) |> JSON.decode!
    signature = Enum.at(claims, 2) |> Base.url_decode64!(padding: false)

    message = Enum.join([Enum.at(claims, 0), Enum.at(claims, 1)], ".")

    kid = Map.get(header, "kid")
    chash = Map.get(payload, "c_hash")

    vf = verify_chash(chash, code)
    vc = verify_client(payload)
    vts = verify_token_signature(message, signature, kid)

    valid = vf && vc && vts
    case valid do
      true -> payload
    end
  end

  defp http_request(url) do
    cacert =  :code.priv_dir(:oauth_azure_activedirectory) ++ '/DigiCertGlobalRootCA.crt.pem'
    :httpc.set_options(socket_opts: [verify: :verify_peer, cacertfile: cacert])

    case :httpc.request(:get, {to_charlist(url), []}, [], []) do
      {:ok, response} -> 
        {{_, 200, 'OK'}, _headers, body} = response
        body
      {:error} -> false
    end
  end

  defp get_discovery_key(url, kid) do
    {status, list} = 
      url
      |> http_request
      |> JSON.decode

    key = Enum.find(list["keys"], fn elem -> elem["kid"] == kid end)

    case status do
      :ok -> key["x5c"]
      :error -> nil
    end
  end

  def openid_configuration(key, tenant_id \\ "common") do
    url = "https://login.microsoftonline.com/#{tenant_id}/v2.0/.well-known/openid-configuration"
    
    openid_config = http_request(url) |> JSON.decode!
    openid_config[key]
  end

  defp verify_chash(chash, code) do
    hash_expected = :crypto.hash(:sha256, code)

    {:ok, hash_received } = chash |> Base.url_decode64(padding: false)

    hash_length = byte_size(hash_received)
    hash_expected = :binary.part(hash_expected, 0, hash_length)
    hash_expected === hash_received
  end

  defp verify_client(claims) do
    configset = OauthAzureActivedirectory.config
    now = :os.system_time(:second)

    Map.get(claims, "aud") == configset[:client_id] and
    Map.get(claims, "tid") == configset[:tenant] and
    Map.get(claims, "iss") == openid_configuration("issuer", configset[:tenant]) and
    # time checks
    now < Map.get(claims, "exp") and
    now >= Map.get(claims, "nbf") and
    now >= Map.get(claims, "iat")
  end

  defp verify_token_signature(message, signature, kid) do
    configset = OauthAzureActivedirectory.config

    public_PEM = openid_configuration("jwks_uri", configset[:tenant])
      |> get_discovery_key(kid)
      |> get_public_key

    [key_entry] = :public_key.pem_decode(public_PEM)
    public_key = :public_key.pem_entry_decode(key_entry)

    :public_key.verify(
      message,
      :sha256,
      signature,
      public_key
    )
  end

  defp get_public_key(cert) do
    spki =
      "-----BEGIN CERTIFICATE-----\n#{cert}\n-----END CERTIFICATE-----"
      |> :public_key.pem_decode
      |> hd
      |> :public_key.pem_entry_decode
      |> elem(1)
      |> elem(7)

    :public_key.pem_entry_encode(:SubjectPublicKeyInfo, spki)
    |> List.wrap
    |> :public_key.pem_encode
  end
end
