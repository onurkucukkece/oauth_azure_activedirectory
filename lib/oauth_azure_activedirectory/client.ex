defmodule OauthAzureActivedirectory.Client do
  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode
  alias OauthAzureActivedirectory.Response

  import OauthAzureActivedirectory.Response

  def logout do
    client = configset[:client_id]
    tenant = configset[:tenant]
    logout_url = "https://login.microsoftonline.com/#{tenant}/oauth2/v2.0/logout"
    logout_redirect_url = configset[:logout_redirect_url] || configset[:redirect_uri]

    "#{logout_url}?client_id=#{client}&post_logout_redirect_uri=#{logout_redirect_url}"
  end

  def client do
  	Client.new([
      strategy: __MODULE__,
      client_id: configset[:client_id],
      client_secret: configset[:client_secret],
      redirect_uri: configset[:redirect_uri],
      logout_redirect_url: configset[:logout_redirect_url],
      authorize_url: "https://login.microsoftonline.com/#{configset[:tenant]}/oauth2/v2.0/authorize",
      token_url: "https://login.microsoftonline.com/#{configset[:tenant]}/oauth2/v2.0/token"
    ])
  end

  def authorize_url! do
    key = :crypto.strong_rand_bytes(64) |> Base.url_encode64
    code_challenge = :crypto.hash(:sha256, key)  |> Base.url_encode64(padding: false)

    params = %{
      response_mode: "form_post",
      response_type: "code id_token",
      scope: configset[:scope] || "openid email",
      code_challenge: code_challenge,
      code_challenge_method: "S256",
      nonce: SecureRandom.uuid
    }

    Client.authorize_url!(client, params)
  end

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def process_callback!(%{params: %{"id_token" => id_token, "code" => code}}) do
    claims = id_token |> String.split(".")

    header = Enum.at(claims, 0) |> Base.url_decode64!(padding: false) |> JSON.decode!
    payload = Enum.at(claims, 1) |> Base.url_decode64!(padding: false) |> JSON.decode!
    signature = Enum.at(claims, 2) |> Base.url_decode64!(padding: false)

    message = Enum.join([Enum.at(claims, 0), Enum.at(claims, 1)], ".")

    kid = Map.get(header, "kid")
    chash = Map.get(payload, "c_hash")

    vf = Response.verify_client(chash, code)
    vc = Response.verify_session(payload)
    vts = Response.verify_signature(message, signature, kid)

    payload
  end

  defp configset do
    OauthAzureActivedirectory.config
  end
end
