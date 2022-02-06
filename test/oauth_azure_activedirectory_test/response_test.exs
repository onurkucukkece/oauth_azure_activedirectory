defmodule OauthAzureActivedirectoryTest.Response do
  use ExUnit.Case
  import Mock

  alias OauthAzureActivedirectory.Response
  alias OauthAzureActivedirectory.Http

  defmacro with_signature_mock(block) do
      quote do
        with_mock Http, [
          request: fn
            (url) ->
              request = url |> String.split("/") |> Enum.reverse |> Enum.at(0)
              case request do
                "keys" -> "test/fixtures/web_keys.json" |> File.read!
                _ -> "test/fixtures/openid_config.json" |> File.read!
              end
          end
        ]
      do
        unquote(block)
      end
    end
  end

  describe "verify_signature" do
    test "returns true when signature is valid" do
      with_signature_mock do
        private_key = "test/fixtures/private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"
        encoded_message = message |> Base.url_encode64(padding: false)
        signature = :public_key.sign(encoded_message, :sha256, private_key)

        assert true == Response.verify_signature(encoded_message, signature, "12345")
      end
    end

    test "returns error when signature is invalid" do
      with_signature_mock do
        private_key = "test/fixtures/wrong-private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"
        encoded_message = message |> Base.url_encode64(padding: false)
        signature = :public_key.sign(encoded_message, :sha256, private_key)
        assert false == Response.verify_signature(encoded_message, signature, "12345")
      end
    end
  end

  describe "verify_client" do
    test "returns true when session is valid" do
      with_signature_mock do
        now = :os.system_time(:second)

        payload = %{
          "nbf" => now - 60,
          "iss" => "https://login.microsoftonline.com/042153ca-e0a2-45ba-b335-9e9a06632174/v2.0",
          "aud" => "58b6472d-deb6-4062-b0fc-88fb4972491e",
          "exp" => now + 60,
          "iat" => now - 60,
          "tid" => "042153ca-e0a2-45ba-b335-9e9a06632174"
        } 
        assert true == Response.verify_client(payload)
      end
    end

    test "returns error when session is expired" do
      with_signature_mock do
        now = :os.system_time(:second)

        payload = %{
          "nbf" => now - 60,
          "iss" => "https://login.microsoftonline.com/042153ca-e0a2-45ba-b335-9e9a06632174/v2.0",
          "aud" => "58b6472d-deb6-4062-b0fc-88fb4972491e",
          "exp" => now - 60,
          "iat" => now - 60,
          "tid" => "042153ca-e0a2-45ba-b335-9e9a06632174"
        } 
        assert false == Response.verify_client(payload)
      end
    end
  end

  describe "verify_code" do
    test "returns true when signature is valid" do
      code = :crypto.strong_rand_bytes(16)
      hash = :crypto.hash(:sha256, code) |> Base.url_encode64(padding: false)         

      assert true == Response.verify_code(hash, code)
    end

    test "returns error when signature is invalid" do
      code = :crypto.strong_rand_bytes(16)
      hash = :crypto.hash(:sha256, :crypto.strong_rand_bytes(16)) |> Base.url_encode64(padding: false)

      assert false == Response.verify_code(hash, code)
    end
  end
end
