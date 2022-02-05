defmodule OauthAzureActivedirectory do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.
  """

  @doc """
  Hello world.

  ## Examples

      iex> OauthAzureActivedirectory.hello
      :world

  """

  def config do
    Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
  end
end
