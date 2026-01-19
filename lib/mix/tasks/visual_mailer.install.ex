defmodule Mix.Tasks.VisualMailer.Install do
  @moduledoc """
  Installs VisualMailer in your Phoenix application.

      $ mix visual_mailer.install

  This will:
  1. Generate database migrations for email templates
  2. Print instructions for JavaScript setup
  3. Show configuration examples
  """

  use Mix.Task

  @shortdoc "Install VisualMailer in your Phoenix application"

  @impl true
  def run(_args) do
    Mix.shell().info(IO.ANSI.cyan() <> "\n=== Installing VisualMailer ===" <> IO.ANSI.reset())

    generate_migration()
    print_js_instructions()
    print_config_instructions()
    print_usage_example()

    Mix.shell().info(IO.ANSI.green() <> "\n✓ Installation complete!" <> IO.ANSI.reset())
    Mix.shell().info("\nNext steps:")
    Mix.shell().info("  1. Run: mix ecto.migrate")
    Mix.shell().info("  2. Add JavaScript hook to your app.js")
    Mix.shell().info("  3. Configure your mailer in config.exs")
  end

  defp generate_migration do
    Mix.shell().info("\n📦 Generating migration...")

    timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
    path = "priv/repo/migrations/#{timestamp}_create_visual_mailer_tables.exs"

    if File.exists?(path) do
      Mix.shell().info("   Migration already exists, skipping...")
    else
      content = migration_template()
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
      Mix.shell().info("   Created: #{path}")
    end
  end

  defp migration_template do
    """
    defmodule MyApp.Repo.Migrations.CreateVisualMailerTables do
      use Ecto.Migration

      def change do
        # Email templates
        create table(:visual_mailer_templates) do
          add :name, :string, null: false
          add :subject, :string
          add :preheader, :string
          add :content_json, :map, null: false
          add :mjml_cache, :text
          add :html_cache, :text
          add :variables, {:array, :map}, default: []
          add :category, :string
          add :status, :string, default: "draft"
          add :site_id, :string
          add :organization_id, :binary_id

          timestamps(type: :utc_datetime)
        end

        create index(:visual_mailer_templates, [:site_id])
        create index(:visual_mailer_templates, [:organization_id])
        create index(:visual_mailer_templates, [:status])
        create index(:visual_mailer_templates, [:category])

        # Email campaigns (optional)
        create table(:visual_mailer_campaigns) do
          add :name, :string, null: false
          add :template_id, references(:visual_mailer_templates, on_delete: :restrict)
          add :status, :string, default: "draft"
          add :scheduled_at, :utc_datetime
          add :started_at, :utc_datetime
          add :completed_at, :utc_datetime
          add :recipient_count, :integer, default: 0
          add :sent_count, :integer, default: 0
          add :failed_count, :integer, default: 0
          add :site_id, :string

          timestamps(type: :utc_datetime)
        end

        create index(:visual_mailer_campaigns, [:template_id])
        create index(:visual_mailer_campaigns, [:status])
        create index(:visual_mailer_campaigns, [:scheduled_at])

        # Send logs (optional)
        create table(:visual_mailer_send_logs) do
          add :campaign_id, references(:visual_mailer_campaigns, on_delete: :delete_all)
          add :recipient_email, :string, null: false
          add :status, :string, default: "pending"
          add :sent_at, :utc_datetime
          add :opened_at, :utc_datetime
          add :clicked_at, :utc_datetime
          add :error_message, :text
          add :variables, :map

          timestamps(type: :utc_datetime)
        end

        create index(:visual_mailer_send_logs, [:campaign_id])
        create index(:visual_mailer_send_logs, [:recipient_email])
        create index(:visual_mailer_send_logs, [:status])
      end
    end
    """
  end

  defp print_js_instructions do
    Mix.shell().info("""

    📝 JavaScript Setup:

       1. Add to package.json dependencies:
          "visual-mailer": "^0.1.0"

       2. Run: cd assets && npm install

       3. Add to assets/js/app.js:

          import { EmailBuilderHook } from "visual-mailer/hooks";

          let liveSocket = new LiveSocket("/live", Socket, {
            hooks: {
              EmailBuilder: EmailBuilderHook,
              // ... your other hooks
            }
          });
    """)
  end

  defp print_config_instructions do
    Mix.shell().info("""

    ⚙️  Configuration (config/config.exs):

       config :visual_mailer,
         repo: MyApp.Repo,           # For Ecto schemas
         mailer: MyApp.Mailer,       # For email sending
         oban_queue: :email_campaigns # For campaign workers
    """)
  end

  defp print_usage_example do
    Mix.shell().info("""

    📖 Usage in LiveView:

       # In your LiveView module
       def mount(_params, _session, socket) do
         {:ok, assign(socket, template: nil)}
       end

       def handle_info({:template_saved, data}, socket) do
         # Save to database
         {:ok, template} = create_or_update_template(data)
         {:noreply, assign(socket, template: template)}
       end

       # In your template
       <.live_component
         module={VisualMailer.BuilderComponent}
         id="email-builder"
         template={@template}
         config={%{brand_color: "#007bff"}}
         on_save={fn data -> send(self(), {:template_saved, data}) end}
       />

    📧 Rendering and sending:

       # Render template
       {:ok, result} = VisualMailer.render(template.content_json,
         variables: %{"name" => "John"}
       )

       # Send email
       email =
         Swoosh.Email.new()
         |> Swoosh.Email.to("user@example.com")
         |> Swoosh.Email.from("noreply@app.com")
         |> Swoosh.Email.subject(template.subject)
         |> Swoosh.Email.html_body(result.html)
         |> Swoosh.Email.text_body(result.plain_text)

       MyApp.Mailer.deliver(email)
    """)
  end
end
