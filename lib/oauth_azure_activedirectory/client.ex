defmodule OauthAzureActivedirectory.Client do
  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  def logout do
    configset = config()
    tenant = configset[:tenant]
    logout_url = openid_configuration("end_session_endpoint", tenant)
    logout_redirect_url = configset[:logout_redirect_url] || configset[:redirect_uri]

    "#{logout_url}?&post_logout_redirect_uri=#{logout_redirect_url}"
  end

  def client do
  	configset = config()

  	Client.new([
      strategy: __MODULE__,
      client_id: configset[:client_id],
      client_secret: configset[:client_secret],
      redirect_uri: configset[:redirect_uri],
      logout_redirect_url: configset[:logout_redirect_url],
      authorize_url: openid_configuration("authorization_endpoint", configset[:tenant]),
      token_url: openid_configuration("token_endpoint", configset[:tenant])
    ])
  end

  def authorize_url! do
    oauth_session = SecureRandom.uuid
    key = :crypto.strong_rand_bytes(64) |> Base.url_encode64()
    code_challenge = :crypto.hash(:sha256, key)  |> Base.url_encode64 |> String.replace("=", "")

    params = %{
      response_mode: "form_post",
      response_type: "code id_token",
      scope: "openid email",
      code_challenge: code_challenge,
      code_challenge_method: "S256",
      nonce: oauth_session
    }

    Client.authorize_url!(client(), params)
  end

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def process_callback!(%{params: %{"id_token" => id_token, "code" => code}}) do
    claims = id_token |> String.split(".")
    
    header = Enum.at(claims, 0) |> Base.url_decode64! |> JSON.decode!
    payload = Enum.at(claims, 1) |> Base.url_decode64! |> JSON.decode!
    signature = Enum.at(claims, 2) |> Base.url_decode64!(padding: false)

    message = Enum.join([Enum.at(claims, 0), Enum.at(claims, 1)], ".")

    kid = Map.get(header, "kid")
    chash = Map.get(payload, "c_hash")

    vf = verify_chash(chash, code)
    vc = verify_client(payload)
    vts = verify_token_signature(message, signature, kid)

    payload
  end

  defp verify_chash(chash, code) do
    hash_expected = :crypto.hash(:sha256, code)

    {:ok, hash_received } = chash |> Base.url_decode64(padding: false)

    hash_length = byte_size(hash_received)
    hash_expected = :binary.part(hash_expected, 0, hash_length)
    hash_expected === hash_received
  end

  defp verify_client(claims) do
    configset = config()
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
    configset = config()

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

  defp config do
    Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
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

  defp openid_configuration(key, tenant_id \\ "common") do
    url = "https://login.microsoftonline.com/#{tenant_id}/v2.0/.well-known/openid-configuration"
    
    openid_config = http_request(url) |> JSON.decode!
    openid_config[key]
  end
end
