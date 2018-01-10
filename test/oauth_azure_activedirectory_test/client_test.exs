defmodule OauthAzureActivedirectoryTest.Client do
  use ExUnit.Case

  doctest OauthAzureActivedirectory.Client

  test "returns authorization url" do
    assert OauthAzureActivedirectory.Client.authorize_url!(%{}) != nil
  end
end
