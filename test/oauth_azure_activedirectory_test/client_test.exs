defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case
  import Mock

  alias OauthAzureActivedirectory.Client
  alias OauthAzureActivedirectory.Response

  defmacro with_signature_mock(block) do
    quote do
      with_mock Response, [validate: fn(claims, _) ->
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
        unquote(block)
      end
    end
  end

  doctest OauthAzureActivedirectory.Client
  describe "verify_token_signature" do
    test "verifies nad returns payload" do
      with_signature_mock do
        private_key = "test/keys/private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"

        signature = :public_key.sign(message, :sha256, private_key) |> Base.url_encode64
        encoded_message = message |> Base.url_encode64

        assert message == Client.process_callback!(%{params: %{"id_token" => "#{encoded_message}.#{signature}", "code" => "code"}})
      end
    end

    test "raises error private key doesn't match" do
      with_signature_mock do
        private_key = "test/keys/wrong-private.key" |> File.read!() |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
        message = "yes"

        signature = :public_key.sign(message, :sha256, private_key) |> Base.url_encode64
        encoded_message = message |> Base.url_encode64

        assert "oops" == Client.process_callback!(%{params: %{"id_token" => "#{encoded_message}.#{signature}", "code" => "code"}})
      end
    end
  end
end
