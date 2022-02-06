defmodule OauthAzureActivedirectoryTest.Response do
  use ExUnit.Case
  import Mock

  alias OauthAzureActivedirectory.Response
  alias OauthAzureActivedirectory.Http

  describe "verify_signature" do
    test "returns true when signature is valid" do
      with_mock Http, [
        request: fn
          ("https://login.microsoftonline.com/042153ca-e0a2-45ba-b335-9e9a06632174/v2.0/.well-known/openid-configuration") -> "{\"jwks_uri\":\"keys_url\"}"
          ("keys_url") -> "test/fixtures/web_keys.json" |> File.read!
        end
      ] do
        private_key = "test/fixtures/private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"
        encoded_message = message |> Base.url_encode64(padding: false)
        signature = :public_key.sign(encoded_message, :sha256, private_key)

        assert true == Response.verify_signature(encoded_message, signature, "12345")
      end
    end
  end
end
