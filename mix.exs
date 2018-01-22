defmodule OauthAzureActivedirectory.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oauth_azure_activedirectory,
      version: "0.1.2",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [espec: :test, "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 0.9.2"},
      {:json, "~> 1.0"},
      {:json_web_token, "~> 0.2"},
      {:secure_random, "~> 0.5"},
      {:httpoison, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:espec, "~> 1.4.6", only: :test},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end

  # Package description
  defp description do
    """
    Omniauth authentication for Azure Active Directory using JWT.
    """
  end

  # Package information
  defp package do
    [
     files: ["lib", "priv", "mix.exs", "README.md", "LICENSE*"],
     maintainers: ["Onur Kucukkece"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/onurkucukkece/oauth_azure_activedirectory"}
    ]
  end
end
