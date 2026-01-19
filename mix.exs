defmodule VisualMailer.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mareksybilak/visual-mailer-ex"

  def project do
    [
      app: :visual_mailer,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "VisualMailer",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {VisualMailer.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # MJML rendering (Rust NIF - super fast!)
      {:mjml, "~> 3.0"},

      # Ecto for schemas (optional)
      {:ecto_sql, "~> 3.10", optional: true},

      # Phoenix LiveView for components (optional)
      {:phoenix_live_view, "~> 0.20 or ~> 1.0", optional: true},

      # Email sending (optional)
      {:swoosh, "~> 1.15", optional: true},

      # Background jobs (optional)
      {:oban, "~> 2.17", optional: true},

      # JSON encoding
      {:jason, "~> 1.4"},

      # Development & Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.1", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end

  defp description do
    """
    Phoenix/Elixir integration for visual-mailer.
    MJML rendering, Ecto schemas, and LiveView components for email templates.
    """
  end

  defp package do
    [
      name: "visual_mailer",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "NPM Package" => "https://www.npmjs.com/package/visual-mailer"
      },
      maintainers: ["Marek Sybilak"],
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        Schemas: [
          VisualMailer.Schema.EmailTemplate,
          VisualMailer.Schema.EmailCampaign,
          VisualMailer.Schema.EmailSendLog
        ],
        Renderer: [
          VisualMailer.Renderer,
          VisualMailer.Renderer.JsonToMjml,
          VisualMailer.Renderer.MjmlCompiler,
          VisualMailer.Renderer.Variables,
          VisualMailer.Renderer.PlainText
        ],
        "LiveView Integration": [
          VisualMailer.BuilderComponent
        ],
        Mailer: [
          VisualMailer.Mailer.SwooshAdapter
        ]
      ]
    ]
  end
end
