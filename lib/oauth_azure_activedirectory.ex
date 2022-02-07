defmodule OauthAzureActivedirectory do
  @moduledoc """
  Documentation for OauthAzureActivedirectory.
  """

  @doc """
  Configuration.

  """

  def config do
    Application.get_env(:oauth_azure_activedirectory, OauthAzureActivedirectory.Client)
  end
end
