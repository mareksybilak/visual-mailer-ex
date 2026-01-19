if Code.ensure_loaded?(Ecto) do
  defmodule VisualMailer.Schema.EmailTemplate do
    @moduledoc """
    Ecto schema for storing email templates.

    ## Fields

    - `name` - Human-readable template name
    - `subject` - Email subject line
    - `preheader` - Preview text shown in email clients
    - `content_json` - The template JSON from the visual editor
    - `mjml_cache` - Cached MJML markup (invalidated on content change)
    - `html_cache` - Cached rendered HTML (invalidated on content change)
    - `variables` - List of variable definitions
    - `category` - Optional category (e.g., "newsletter", "transactional")
    - `status` - Template status (draft, published, archived)
    - `site_id` - For multi-tenant applications
    - `organization_id` - For multi-tenant applications

    ## Usage

        # Create a new template
        %EmailTemplate{}
        |> EmailTemplate.changeset(%{
          name: "Welcome Email",
          subject: "Welcome to {{company}}!",
          content_json: %{...}
        })
        |> Repo.insert()

        # Update template (cache automatically invalidated)
        template
        |> EmailTemplate.changeset(%{content_json: new_content})
        |> Repo.update()

    """

    use Ecto.Schema
    import Ecto.Changeset

    @type t :: %__MODULE__{
            id: integer() | nil,
            name: String.t() | nil,
            subject: String.t() | nil,
            preheader: String.t() | nil,
            content_json: map() | nil,
            mjml_cache: String.t() | nil,
            html_cache: String.t() | nil,
            variables: [map()] | nil,
            category: String.t() | nil,
            status: atom() | nil,
            site_id: String.t() | nil,
            organization_id: Ecto.UUID.t() | nil,
            inserted_at: DateTime.t() | nil,
            updated_at: DateTime.t() | nil
          }

    schema "visual_mailer_templates" do
      field :name, :string
      field :subject, :string
      field :preheader, :string
      field :content_json, :map
      field :mjml_cache, :string
      field :html_cache, :string
      field :variables, {:array, :map}, default: []
      field :category, :string
      field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft

      # Multi-tenant support
      field :site_id, :string
      field :organization_id, Ecto.UUID

      timestamps(type: :utc_datetime)
    end

    @required_fields ~w(name content_json)a
    @optional_fields ~w(subject preheader variables category status site_id organization_id)a

    @doc """
    Creates a changeset for an email template.

    Automatically invalidates cached MJML and HTML when content changes.
    """
    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(template, attrs) do
      template
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_length(:name, min: 1, max: 255)
      |> validate_length(:subject, max: 255)
      |> validate_length(:preheader, max: 255)
      |> validate_content_json()
      |> invalidate_cache_on_content_change()
    end

    @doc """
    Creates a changeset for publishing a template.
    """
    @spec publish_changeset(t()) :: Ecto.Changeset.t()
    def publish_changeset(template) do
      change(template, status: :published)
    end

    @doc """
    Creates a changeset for archiving a template.
    """
    @spec archive_changeset(t()) :: Ecto.Changeset.t()
    def archive_changeset(template) do
      change(template, status: :archived)
    end

    # Private functions

    defp validate_content_json(changeset) do
      validate_change(changeset, :content_json, fn :content_json, json ->
        case VisualMailer.Validator.validate(json) do
          :ok -> []
          {:error, errors} -> [content_json: Enum.join(errors, "; ")]
        end
      end)
    end

    defp invalidate_cache_on_content_change(changeset) do
      if get_change(changeset, :content_json) do
        changeset
        |> put_change(:mjml_cache, nil)
        |> put_change(:html_cache, nil)
      else
        changeset
      end
    end
  end
end
