defmodule OauthAzureActivedirectory.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oauth_azure_activedirectory,
      version: "1.2.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.circle": :test, "coveralls.html": :test]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:json, "~> 1.0"},
      {:secure_random, "~> 0.5.1"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:mock, "~> 0.3.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
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
