defmodule OauthAzureActivedirectory.Response do
  alias OauthAzureActivedirectory.Http

  @moduledoc """
  Documentation for OauthAzureActivedirectory.Response
  """
  @moduledoc since: "1.0.0"

  @doc """
  Validates code param with c_hash in id_token

  """
  def verify_code(chash, code) do
    hash_expected = :crypto.hash(:sha256, code)

    hash_received = chash |> Base.url_decode64!(padding: false)

    hash_length = byte_size(hash_received)
    hash_expected = :binary.part(hash_expected, 0, hash_length)
    hash_expected === hash_received
  end

  @doc """
  Validates client and session attributes

  """
  def verify_client(claims) do
    now = :os.system_time(:second)

    Map.get(claims, "aud") == configset()[:client_id] and
    Map.get(claims, "tid") == configset()[:tenant] and
    Map.get(claims, "iss") == openid_configuration("issuer") and
    # time checks
    now < Map.get(claims, "exp") and
    now >= Map.get(claims, "nbf") and
    now >= Map.get(claims, "iat")
  end

  @doc """
  Verifies signature in JWT token

  """
  def verify_signature(message, signature, kid) do
    public_pem = openid_configuration("jwks_uri")
      |> get_discovery_key(kid)
      |> get_public_key

    [key_entry] = :public_key.pem_decode(public_pem)
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
    url = "#{OauthAzureActivedirectory.base_url()}/#{configset()[:tenant]}/v2.0/.well-known/openid-configuration"

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
    OauthAzureActivedirectory.config()
  end
end
