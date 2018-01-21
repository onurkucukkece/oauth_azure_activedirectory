defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case

  doctest OauthAzureActivedirectory.Client

  test "returns authorization url" do
    app_config = Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
		auth_url = OauthAzureActivedirectory.Client.authorize_url!(%{})
		url = URI.parse auth_url
  	
    assert url.host == "login.microsoftonline.com"
    assert url.path == "/#{app_config[:tenant]}/oauth2/authorize"
    assert url.port == 443

    url_query = URI.decode_query(url.query)
    assert url_query["client_id"] == app_config[:client_id]
    assert url_query["response_mode"] == "form_post"
    assert url_query["response_type"] == "code id_token"
    assert String.match?(url_query["nonce"], ~r/^[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12}$/)
  end

  test "returns decoded jwt token" do
    app_config = Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
    case :httpc.request(:get, {to_charlist(System.get_env("TEST_TOKEN_URL")), []}, [], []) do
      {:ok, response} -> 
          {{_, 200, 'OK'}, _headers, body} = response
          {:ok, json} = JSON.decode body
          params = %{params: json}
          {:ok, jwt} = OauthAzureActivedirectory.Client.process_callback!(params)
          assert jwt[:given_name] == "Onur"
          assert jwt[:family_name] == "Kucukkece"
          assert jwt[:tid] == app_config[:tenant]
          assert jwt[:c_hash] == "FWkv4C_hs-f_195tbgkUjw"
      {:error} -> false
    end
  end
end

