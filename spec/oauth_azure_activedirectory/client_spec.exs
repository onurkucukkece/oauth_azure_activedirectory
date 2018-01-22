defmodule OauthAzureActivedirectory.ClientSpec do
  use ESpec

  let :x5c, do: File.read "#{File.cwd!}/spec/fixtures/x5c.txt"
  let :id_token, do: File.read "#{File.cwd!}/spec/fixtures/id_token.txt"

  # These values were used to create the "successful" id_token JWT.
  let :client_id, do: 'the client id'
  let :code, do: 'code'
  let :email, do: 'jsmith@contoso.com'
  let :family_name, do: 'smith'
  let :given_name, do: 'John'
  let :issuer, do: 'https://sts.windows.net/bunch-of-random-chars'
  let :kid, do: 'abc123'
  let :name, do: 'John Smith'
  let :nonce, do: 'my nonce'
  let :session_state, do: 'session state'
  let :auth_endpoint_host, do: 'authorize.com'
  let :tenant, do: 'tenant' 
  let :openid_config_response, do: "{\"issuer\":\"#{issuer}\",\"authorization_endpoint\":\"http://#{auth_endpoint_host}\",\"jwks_uri\":\"https://login.windows.net/common/discovery/keys\"}" 
  let :keys_response, do: "{\"keys\":[{\"kid\":\"#{kid}\",\"x5c\":[\"#{x5c}\"]}]}" 
  let(:hybrid_flow_params) do
    %{ 'id_token' => id_token,
      'session_state' => session_state,
      'code' => code }
  end
end