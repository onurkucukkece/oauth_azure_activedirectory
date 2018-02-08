defmodule OauthAzureActivedirectory.ClientSpec do
  use ESpec

  alias OauthAzureActivedirectory.Client

  before_all do
    allow SecureRandom |> to(accept :uuid, fn() -> "my nonce" end)
  end

  let :x5c do
    {status, response} = File.read "#{File.cwd!}/spec/fixtures/x5c.txt"
    response
  end
  let :id_token do
    {status, response} = File.read "#{File.cwd!}/spec/fixtures/id_token.txt"
    response
  end

  # These values were used to create the "successful" id_token JWT.
  let :code, do: 'code'
  let :email, do: 'jsmith@contoso.com'
  let :family_name, do: 'smith'
  let :given_name, do: 'John'
  let :issuer, do: 'https://sts.windows.net/bunch-of-random-chars'
  let :kid, do: 'abc123'
  let :name, do: 'John Smith'
  let :session_state, do: 'session state'
  let :auth_endpoint_host, do: 'authorize.com'
  let :openid_config_response, do: "{\"issuer\":\"#{issuer}\",\"authorization_endpoint\":\"http://#{auth_endpoint_host}\",\"jwks_uri\":\"https://login.windows.net/common/discovery/keys\"}" 
  let :keys_response, do: "{\"keys\":[{\"kid\":\"#{kid}\",\"x5c\":[\"#{x5c}\"]}]}" 
  let(:hybrid_flow_params) do
    %{ 'id_token' => id_token,
      'session_state' => session_state,
      'code' => code }
  end

  context "authorize" do 
    it "returns authorize url" do
      url = URI.parse Client.authorize_url!(%{})
      expect url.host |> to(eq "login.microsoftonline.com")
      expect url.path |> to(eq "/tenant/oauth2/authorize")
      expect url.port |> to(eq 443)

      url_query = URI.decode_query(url.query)
      expect url_query["client_id"] |> to(eq "the client id")
      expect url_query["response_mode"] |> to(eq "form_post")
      expect url_query["response_type"] |> to(eq "code id_token")
      expect url_query["nonce"] |> to(eq "my nonce")
    end
  end

  context "process_callback" do
    xit "returns user claims with right code and id_token" do
      :meck.new(HTTPoison)
      :meck.expect(HTTPoison, :get, fn(url) -> if url == "https://login.microsoftonline.com/common/.well-known/openid-configuration", do: openid_config_response, else: keys_response  end)
      {status, jwt} = Client.process_callback!(%{params: %{"id_token" => id_token, "code" => code}})
      :meck.unload(HTTPoison)
      expect status |> to(eq :ok)
    end
  end
end
