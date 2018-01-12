defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case

  doctest OauthAzureActivedirectory.Client

  test "returns authorization url" do
		auth_url = OauthAzureActivedirectory.Client.authorize_url!(%{})
		url = URI.parse auth_url
  	
    assert url.host == "login.microsoftonline.com"
    assert url.path == "/tenant/oauth2/authorize"
    assert url.port == 443

    url_query = URI.decode_query(url.query)
    assert url_query["client_id"] == "client_id"
    assert url_query["response_mode"] == "form_post"
    assert url_query["response_type"] == "code id_token"
    assert String.match?(url_query["nonce"], ~r/^[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12}$/)
  end
end

