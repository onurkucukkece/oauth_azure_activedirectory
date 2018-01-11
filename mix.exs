defmodule OauthAzureActivedirectory.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oauth_azure_activedirectory,
      version: "0.1.0-alpha",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description(),
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
      {:ex_doc, ">= 0.0.0", only: :dev}
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
     files: ["lib", "mix.exs", "README.md", "LICENSE*"],
     maintainers: ["Onur Kucukkece"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/onurkucukkece/oauth_azure_activedirectory"}
    ]
  end
end
