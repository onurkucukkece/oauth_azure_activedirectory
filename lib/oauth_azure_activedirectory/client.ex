defmodule OauthAzureActivedirectory.Client do
  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode
  alias JsonWebToken.Algorithm.RsaUtil
  alias OauthAzureActivedirectory.NonceAgent

  def logout(redirect_uri) do
  	configset = config()
    tenant = configset[:tenant]
    client = configset[:client_id]

    "https://login.microsoftonline.com/#{tenant}/oauth2/logout?client_id=#{client
    }&post_logout_redirect_uri=#{redirect_uri}"
  end

  def client do
  	configset = config()

  	Client.new([
      strategy: __MODULE__,
      client_id: configset[:client_id],
      client_secret: configset[:client_secret],
      redirect_uri: configset[:redirect_uri],
      authorize_url: "https://login.microsoftonline.com/#{configset[:tenant]}/oauth2/authorize",
      token_url: "https://login.microsoftonline.com/#{configset[:tenant]}/oauth2/token"
    ])
  end

  def authorize_url!(params \\ []) do
    oauth_session = SecureRandom.uuid
    NonceAgent.put(oauth_session)
    
    params =
      params
      |> Map.update(:response_mode, "form_post", &(&1 * "form_post"))
      |> Map.update(:response_type, "code id_token", &(&1 * "code id_token"))
      |> Map.update(:nonce, oauth_session, &(&1 * oauth_session))

    Client.authorize_url!(client(), params)
  end

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def process_callback!(%{params: %{"id_token" => id_token, "code" => code}}) do
    public =
      jwks_uri()
      |> get_discovery_keys
      |> get_public_key
      |> RsaUtil.public_key

    opts = %{
      alg: "RS256",
      key: public
    }

    {:ok, claims} = JsonWebToken.verify(id_token, opts)
    verify_token(code, claims)
  end

  defp config do
    Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
  end

  defp jwks_uri do
    {status, list} =
      open_id_configuration()
      |> http_request
      |> JSON.decode

    if status == :ok do
      list["jwks_uri"]
    else
      nil
    end
  end

  defp http_request(url) do
    cacert =  :code.priv_dir(:oauth_azure_activedirectory) ++ '/BaltimoreCyberTrustRoot.crt.pem'
    :httpc.set_options(socket_opts: [verify: :verify_peer, cacertfile: cacert])

    case :httpc.request(:get, {to_charlist(url), []}, [], []) do
      {:ok, response} -> 
        {{_, 200, 'OK'}, _headers, body} = response
        body
      {:error} -> false
    end
  end

  defp get_discovery_keys(url)do
    {status, list} = 
      url
      |> http_request
      |> JSON.decode

    case status do
      :ok -> Enum.at(list["keys"], 0)["x5c"]
      :error -> nil
    end
  end

  defp get_public_key(cert) do
    spki =
      "-----BEGIN CERTIFICATE-----\n#{cert}\n-----END CERTIFICATE-----\n"
      |> :public_key.pem_decode
      |> hd
      |> :public_key.pem_entry_decode
      |> elem(1)
      |> elem(7)
    
    :public_key.pem_entry_encode(:SubjectPublicKeyInfo, spki)
    |> List.wrap
    |> :public_key.pem_encode
  end

  defp open_id_configuration do
    "https://login.microsoftonline.com/common/.well-known/openid-configuration"
  end

  defp verify_token(code, claims) do
    claims
    |> verify_chash(code)
    |> verify_client
  end

  defp verify_chash(claims, code) do
    hash_actual = :crypto.hash(:sha256, code)

    {:ok, hash_expected } =
      claims[:c_hash]
      |> Base.url_decode64(padding: false)

    hash_length = byte_size(hash_expected)
    hash_actual = :binary.part(hash_actual, 0, hash_length)
    ^hash_actual = hash_expected

    claims
  end

  defp verify_client(claims) do
    configset = config()
    now = :os.system_time(:second)

    is_valid =
      # audience
      configset[:client_id] == claims[:aud] and
      # tenant/issuer
      configset[:tenant] == claims[:tid] and
      "https://sts.windows.net/#{configset[:tenant]}/" == claims[:iss] and
      # time checks
      now < claims[:exp] and
      now >= claims[:nbf] and
      now >= claims[:iat] and
      # nonce
      NonceAgent.check_and_delete(claims[:nonce])

    true = is_valid
    claims
  end
end

defmodule OauthAzureActivedirectory.NonceAgent do
  use Agent

  def start_link() do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def put(nonce) do
    Agent.update(__MODULE__, &MapSet.put(&1, nonce))
  end

  def check_and_delete(nonce) do
    is_member = Agent.get(__MODULE__, &MapSet.member?(&1, nonce))
    Agent.update(__MODULE__, &MapSet.delete(&1, nonce))
    is_member
  end
end
