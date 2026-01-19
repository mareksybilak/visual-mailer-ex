# VisualMailer

[![Hex.pm](https://img.shields.io/hexpm/v/visual_mailer.svg)](https://hex.pm/packages/visual_mailer)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/visual_mailer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Phoenix/Elixir integration for [visual-mailer](https://www.npmjs.com/package/visual-mailer). MJML rendering, Ecto schemas, and LiveView components for email templates.

## Features

- 🚀 **Fast MJML Rendering** - Uses Rust NIF for ~10x faster compilation than Node.js
- 📝 **Ecto Schemas** - Ready-to-use schemas for templates and campaigns
- 🔌 **LiveView Integration** - Seamless integration with Phoenix LiveView
- 📧 **Swoosh Support** - Easy email sending via your configured mailer
- 🔄 **Variable Interpolation** - `{{variable}}` syntax with defaults support

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:visual_mailer, "~> 0.1.0"}
  ]
end
```

Run the installer:

```bash
mix visual_mailer.install
mix ecto.migrate
```

## Quick Start

### 1. Add JavaScript Hook

```javascript
// assets/js/app.js
import { EmailBuilderHook } from "visual-mailer/hooks";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    EmailBuilder: EmailBuilderHook,
  }
});
```

### 2. Use in LiveView

```elixir
# In your LiveView
def mount(_params, _session, socket) do
  {:ok, assign(socket, template: nil)}
end

def handle_info({:template_saved, data}, socket) do
  # Save to database
  {:ok, template} = save_template(data)
  {:noreply, assign(socket, template: template)}
end
```

```heex
<!-- In your template -->
<.live_component
  module={VisualMailer.BuilderComponent}
  id="email-builder"
  template={@template}
  config={%{brand_color: "#007bff"}}
  variables={[
    %{key: "first_name", label: "First Name"},
    %{key: "company", label: "Company"}
  ]}
  on_save={fn data -> send(self(), {:template_saved, data}) end}
/>
```

### 3. Render and Send Emails

```elixir
# Render template with variables
{:ok, result} = VisualMailer.render(template.content_json,
  variables: %{"first_name" => "John", "company" => "ACME"}
)

# result contains:
# - result.html       - Ready-to-send HTML
# - result.plain_text - Plain text version
# - result.mjml       - Intermediate MJML

# Send via Swoosh
email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("user@example.com")
  |> Swoosh.Email.from("noreply@yourapp.com")
  |> Swoosh.Email.subject("Welcome!")
  |> Swoosh.Email.html_body(result.html)
  |> Swoosh.Email.text_body(result.plain_text)

MyApp.Mailer.deliver(email)
```

## Configuration

```elixir
# config/config.exs
config :visual_mailer,
  repo: MyApp.Repo,           # For Ecto schemas
  mailer: MyApp.Mailer,       # For email sending
  oban_queue: :email_campaigns # For campaign workers
```

## Variable Interpolation

Supports `{{variable}}` syntax:

```elixir
# Simple variable
"Hello {{name}}!" + %{"name" => "John"} = "Hello John!"

# With default value
"Hello {{name|default:Guest}}!" + %{} = "Hello Guest!"

# Extract variables from template
VisualMailer.Renderer.Variables.extract_variables("Hello {{name}}!")
# => ["name"]
```

## Ecto Schemas

```elixir
# Create a template
%VisualMailer.Schema.EmailTemplate{}
|> VisualMailer.Schema.EmailTemplate.changeset(%{
  name: "Welcome Email",
  subject: "Welcome to {{company}}!",
  content_json: %{...}
})
|> Repo.insert()
```

## Performance

MJML compilation uses a Rust NIF (via the `mjml` hex package):

| Template Size | Compilation Time |
|--------------|------------------|
| Simple (5 blocks) | ~1-2ms |
| Medium (20 blocks) | ~3-5ms |
| Complex (50+ blocks) | ~10-15ms |

## Related Packages

- [visual-mailer](https://www.npmjs.com/package/visual-mailer) - React visual editor (NPM)
- [mjml](https://hex.pm/packages/mjml) - MJML Rust NIF (Hex)

## License

MIT © [Marek Sybilak](https://github.com/mareksybilak)
