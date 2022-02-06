defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case, async: false

  import Mock

  alias OauthAzureActivedirectory.Client
  alias OauthAzureActivedirectory.Error
  alias OauthAzureActivedirectory.Response

  describe "process_callback!" do
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
        assert {:ok, payload} == Client.process_callback!(params)
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
        assert {:error, %Error{module: Client, reason: :invalid_code}} == Client.process_callback!(params)
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
        assert {:error, %Error{module: Client, reason: :invalid_client}} == Client.process_callback!(params)
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
        assert {:error, %Error{module: Client, reason: :invalid_signature}} == Client.process_callback!(params)
      end
    end
  end
end
