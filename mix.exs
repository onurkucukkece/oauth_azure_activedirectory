defmodule OauthAzureActivedirectory.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oauth_azure_activedirectory,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 0.9.2"},
      {:json, "~> 1.0"},
      {:json_web_token, "~> 0.2"},
      {:secure_random, "~> 0.5"},
    ]
  end
end
