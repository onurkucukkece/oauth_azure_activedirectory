defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case
  import Mock

  alias OauthAzureActivedirectory.Client
  alias OauthAzureActivedirectory.Response

  doctest OauthAzureActivedirectory.Client
  test "verify_token_signature" do
    with_mock Response,
      [validate: fn(claims, _) -> 
        [encoded_message, encoded_signature] = claims

        message = encoded_message |> Base.url_decode64!(padding: false)
        signature = encoded_signature |> Base.url_decode64!(padding: false)
        public_PEM = "test/keys/public.key" |> File.read!()
        [key_entry] = :public_key.pem_decode(public_PEM)
        public_key = :public_key.pem_entry_decode(key_entry)

        verify = :public_key.verify(
          message,
          :sha256,
          signature,
          public_key
        )

        case verify do
          true -> message
          false -> "oops"
        end
      end] do
        private_key = "test/keys/private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"

        signature = :public_key.sign(message, :sha256, private_key) |> Base.url_encode64
        encoded_message = message |> Base.url_encode64

        assert message == Client.process_callback!(%{params: %{"id_token" => "#{encoded_message}.#{signature}", "code" => "code"}})
      end
  end
end

