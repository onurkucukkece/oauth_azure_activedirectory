defmodule OauthAzureActivedirectory.Response do
  alias OauthAzureActivedirectory.Http

  import OauthAzureActivedirectory.Http

  def verify_client(chash, code) do
    hash_expected = :crypto.hash(:sha256, code)

    {:ok, hash_received } = chash |> Base.url_decode64(padding: false)

    hash_length = byte_size(hash_received)
    hash_expected = :binary.part(hash_expected, 0, hash_length)
    hash_expected === hash_received
  end

  def verify_session(claims) do
    now = :os.system_time(:second)

    Map.get(claims, "aud") == configset[:client_id] and
    Map.get(claims, "tid") == configset[:tenant] and
    Map.get(claims, "iss") == openid_configuration("issuer") and
    # time checks
    now < Map.get(claims, "exp") and
    now >= Map.get(claims, "nbf") and
    now >= Map.get(claims, "iat")
  end

  def verify_signature(message, signature, kid) do
    public_PEM = openid_configuration("jwks_uri")
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

  defp get_discovery_key(url, kid) do
    {status, list} = 
      url
      |> Http.request
      |> JSON.decode

    key = Enum.find(list["keys"], fn elem -> elem["kid"] == kid end)

    case status do
      :ok -> key["x5c"]
      :error -> nil
    end
  end

  def openid_configuration(key) do
    url = "https://login.microsoftonline.com/#{configset[:tenant]}/v2.0/.well-known/openid-configuration"
    
    openid_config = Http.request(url) |> JSON.decode!
    openid_config[key]
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

  defp configset do
    OauthAzureActivedirectory.config
  end
end
