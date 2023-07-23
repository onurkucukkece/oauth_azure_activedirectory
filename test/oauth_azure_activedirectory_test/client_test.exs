defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case, async: false

  import Mock

  alias OauthAzureActivedirectory.Client
  alias OauthAzureActivedirectory.Error
  alias OauthAzureActivedirectory.Response

  describe "logout_url" do
    test "returns logout url" do
      app_config = Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
      auth_url = OauthAzureActivedirectory.Client.logout_url
      url = URI.parse auth_url

      assert url.host == "login.microsoftonline.com"
      assert url.path == "/#{app_config[:tenant]}/oauth2/v2.0/logout"
      assert url.port == 443

      url_query = URI.decode_query(url.query)
      assert url_query["client_id"] == app_config[:client_id]
      assert url_query["post_logout_redirect_uri"] == app_config[:redirect_uri]
    end
  end

  describe "authorize_url!" do
    test "returns authorize url" do
      app_config = Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
      auth_url = OauthAzureActivedirectory.Client.authorize_url!()
      url = URI.parse auth_url

      assert url.host == "login.microsoftonline.com"
      assert url.path == "/#{app_config[:tenant]}/oauth2/v2.0/authorize"
      assert url.port == 443

      url_query = URI.decode_query(url.query)
      assert url_query["client_id"] == app_config[:client_id]
      assert url_query["response_mode"] == "form_post"
      assert url_query["response_type"] == "code id_token"
      assert url_query["code_challenge_method"] == "S256"
      assert String.match?(url_query["code_challenge"], ~r/^[-A-Za-z0-9+=]{1,50}|=[^=]|={3,}$/)
      assert String.match?(url_query["nonce"], ~r/^[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12}$/)
    end

    test "allows custom state for multiple requests" do
      auth_url = OauthAzureActivedirectory.Client.authorize_url!("custom_state")
      url = URI.parse auth_url
      url_query = URI.decode_query(url.query)
      assert url_query["state"] == "custom_state"
    end
  end

  describe "callback_params" do
    test "returns payload when request is valid" do
      with_mock Response,
        [
          verify_code: fn(_, _) -> true end,
          verify_client: fn(_) -> true end,
          verify_signature: fn(_, _, _) -> true end
        ]
      do
        payload = %{"c_hash" => "MeUkiAQXgYSiaiAYZacYEA"}
        payload_encoded = payload |> JSON.encode! |> Base.url_encode64(padding: false)
        params = %{params: %{"id_token" => "e30.#{payload_encoded}.", "code" => "code"}}
        assert {:ok, payload} == Client.callback_params(params)
      end
    end

    test "returns invalid code error when code is not valid" do
      with_mock Response,
        [
          verify_code: fn(_, _) -> false end,
          verify_client: fn(_) -> true end,
          verify_signature: fn(_, _, _) -> true end
        ]
      do
        params = %{params: %{"id_token" => "e30.e30.", "code" => "code"}}
        assert {:error, %Error{module: Client, reason: :invalid_code}} == Client.callback_params(params)
      end
    end

    test "returns invalid client error when client is not valid" do
      with_mock Response,
        [
          verify_code: fn(_, _) -> true end,
          verify_client: fn(_) -> false end,
          verify_signature: fn(_, _, _) -> true end
        ]
      do
        params = %{params: %{"id_token" => "e30.e30.", "code" => "code"}}
        assert {:error, %Error{module: Client, reason: :invalid_client}} == Client.callback_params(params)
      end
    end

    test "returns invalid signature error when signature is not valid" do
      with_mock Response,
        [
          verify_code: fn(_, _) -> true end,
          verify_client: fn(_) -> true end,
          verify_signature: fn(_, _, _) -> false end
        ]
      do
        params = %{params: %{"id_token" => "e30.e30.", "code" => "code"}}
        assert {:error, %Error{module: Client, reason: :invalid_signature}} == Client.callback_params(params)
      end
    end
  end
end
