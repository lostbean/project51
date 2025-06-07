# 🚀 Complete Guide: Building a Real-Time Collaborative Application

This comprehensive guide walks you through building a production-ready real-time collaborative application featuring Elixir/Phoenix backend, React frontend, and advanced patterns for LLM integration, job processing, and real-time communication.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites & Environment Setup](#prerequisites--environment-setup)
3. [Project Initialization](#project-initialization)
4. [Core Dependencies & Configuration](#core-dependencies--configuration)
5. [Database & Ecto Setup](#database--ecto-setup)
6. [Authentication System](#authentication-system)
7. [Real-Time Architecture with LiveState](#real-time-architecture-with-livestate)
8. [Background Job Processing with Oban](#background-job-processing-with-oban)
9. [LLM Integration with Reactor](#llm-integration-with-reactor)
10. [Frontend Setup with React & TypeScript](#frontend-setup-with-react--typescript)
11. [Observability & Monitoring](#observability--monitoring)
12. [Deployment Configuration](#deployment-configuration)
13. [Testing Strategy](#testing-strategy)
14. [Development Workflow](#development-workflow)

## 🏗️ Architecture Overview

This project implements a modular, single-application architecture using Phoenix with clear namespace separation:

- **MyApp.Core**: Domain models and core business logic
- **MyApp.Data**: Data persistence layer with Ecto schemas
- **MyApp.Jobs**: Background job processing with job-specific contexts
- **MyApp.LLM**: LLM integration using Reactor workflows
- **MyApp.Web**: HTTP/WebSocket interfaces with real-time PubSub
- **MyApp.Gleam**: Type-safe state modeling with compile-time guarantees and functional programming patterns (optional)
- **Reactor.Middleware**: Observability middleware for workflows

### Key Technologies

- **Backend**: Elixir 1.18+, Phoenix 1.7+, LiveState, Oban, Reactor
- **Frontend**: React 18+, TypeScript, Chakra UI, ESBuild
- **Database**: SQLite (development), PostgreSQL (production)
- **LLM**: OpenAI integration with Instructor for structured outputs
- **Auth**: Auth0 with JWT validation
- **Observability**: OpenTelemetry, Prometheus, Grafana

## 🔧 Prerequisites & Environment Setup

### 1. Install Core Dependencies

#### Using Nix (Recommended)
```bash
# Create flake.nix
cat > flake.nix << 'EOF'
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir ecosystem
            beam.packages.erlang.elixir_1_18
            gleam

            # Node.js for frontend
            nodejs_22

            # Database
            sqlite

            # Development tools
            git
            just
            docker
            docker-compose
          ];

          shellHook = ''
            echo "🚀 MyApp Development Environment Ready!"
            echo "Elixir: $(elixir --version | head -1)"
            echo "Node: $(node --version)"
          '';
        };
      });
}
EOF

# Enter development environment
nix develop
```

#### Manual Installation
```bash
# Install Elixir 1.18+
brew install elixir gleam

# Install Node.js 22+
brew install node

# Install database
brew install sqlite postgresql

# Install development tools
brew install git docker docker-compose
```

### 2. Environment Variables

Create `.env` file:
```bash
# Auth0 Configuration
APP_AUTH0_DOMAIN=your-domain.auth0.com
APP_AUTH0_CLIENT_ID=your-client-id
APP_AUTH0_AUDIENCE=https://your-api-identifier
APP_AUTH0_JWKS_URL=https://your-domain.auth0.com/.well-known/jwks.json

# OpenAI Configuration
OPENAI_API_KEY=your-openai-api-key

# Database
DATABASE_URL=sqlite:///data/my_app.db

# Observability
OTLP_ENDPOINT=http://localhost:4318/v1/traces

# Phoenix
SECRET_KEY_BASE=$(mix phx.gen.secret)
```

## 🎯 Project Initialization

### 1. Create Phoenix Project

```bash
# Create new Phoenix project (replace 'my_app' with your app name)
mix phx.new my_app --no-live --no-gettext --database sqlite3
cd my_app

# Initialize git
git init
git add .
git commit -m "Initial Phoenix project"
```

### 2. Basic Project Structure

> **💡 Organization Tip**: Use **plural form for context modules** (e.g., "Users" for users table) and **singular form for schema modules** (e.g., "User" for users table). Split reactors and steps into **non-hierarchical folders** for better composability.

```bash
# Create core namespace directories (replace 'my_app' with your app name)
mkdir -p lib/my_app/{core,data,jobs,llm,gleam}
mkdir -p lib/my_app/llm/{agents,reactors,steps,schemas,workers}
mkdir -p lib/my_app/jobs/{content_generation_job}  # Example job type
mkdir -p lib/my_app/web/{auth,channels,plugs}
mkdir -p lib/reactor/middleware

# Create test directories
mkdir -p test/my_app/{core,data,jobs,llm,web}
mkdir -p test/reactor/middleware

# Create assets structure
mkdir -p assets/js/{auth,components,hooks,types}
```

### 📂 Detailed Folder Structure Pattern

The project follows a **domain-driven namespace pattern** within a single application, promoting maintainability and clear separation of concerns:

> **🎯 Key Pattern**: This structure supports **scalable job organization** using job-specific context modules instead of monolithic modules, **data layer separation** with embedded context functions, and **loosely coupled telemetry** using behavior patterns.

```
lib/my_app/
├── core/                          # Domain models (business logic)
│   ├── user.ex                    # Core domain entities
│   ├── session.ex
│   ├── content.ex
│   └── workspace.ex
├── data/                          # Data persistence layer
│   ├── repo.ex
│   ├── user.ex                    # Ecto schema + context functions
│   ├── session.ex
│   ├── content.ex
│   ├── activity_log.ex
│   └── jobs/                      # Job-specific data schemas
│       └── content_generation_job.ex
├── jobs/                          # Background job contexts
│   ├── job_handler.ex             # Behavior for job handlers
│   ├── content_generation_job.ex  # Job context module
│   ├── content_generation_job/
│   │   └── telemetry_handler.ex   # Job-specific telemetry
│   └── oban_telemetry_handler.ex  # Generic telemetry dispatcher
├── llm/                           # LLM integration
│   ├── agent.ex
│   ├── content_agent.ex
│   ├── analysis_agent.ex
│   ├── reactors/                  # Workflow orchestration
│   │   ├── content_reactor.ex
│   │   └── analysis_reactor.ex
│   ├── schemas/                   # Structured LLM outputs
│   │   ├── content.ex
│   │   └── analysis.ex
│   ├── steps/                     # Individual workflow steps
│   │   ├── generate_content_step.ex
│   │   ├── analyze_sentiment_step.ex
│   │   └── extract_keywords_step.ex
│   └── workers/                   # Oban workers
│       └── content_generation_worker.ex
├── web/                           # Phoenix web interface
│   ├── application.ex
│   ├── endpoint.ex
│   ├── router.ex
│   ├── telemetry.ex
│   ├── auth/                      # Authentication
│   │   └── guardian.ex
│   ├── channels/                  # Real-time channels
│   │   ├── channel_init.ex
│   │   ├── workspace_channel.ex
│   │   ├── job_management_channel.ex
│   │   ├── live_state_socket.ex
│   │   └── session_list_channel.ex
│   ├── controllers/               # HTTP controllers
│   │   ├── auth_controller.ex
│   │   ├── error_json.ex
│   │   ├── page_controller.ex
│   │   └── page_html.ex
│   ├── plugs/                     # Custom plugs
│   │   └── require_auth.ex
│   └── prom_ex/                   # Metrics
│       └── plugins/
│           └── reactor_plugin.ex
├── gleam/                         # Gleam integration (optional)
│   ├── my_app_gleam.ex           # Main Gleam module bridge
│   ├── state/                    # Gleam state models
│   │   ├── session_state.gleam
│   │   ├── user_state.gleam
│   │   └── collaboration_state.gleam
│   └── types/                    # Shared type definitions
│       ├── session.gleam
│       ├── user.gleam
│       └── content.gleam
└── reactor/                       # Shared middleware
    └── middleware/
        ├── config.ex
        ├── opentelemetry_middleware.ex
        ├── structured_logging_middleware.ex
        ├── telemetry_events_middleware.ex
        └── utils.ex
```

### 🎯 Key Organizational Principles

1. **Domain Separation**: Each namespace has a clear responsibility
2. **Non-hierarchical Organization**: Steps and reactors are in flat folders for better composability
3. **Job-specific Contexts**: Each job type gets its own context module for scalability
4. **Data Layer Separation**: Ecto schemas include embedded context functions
5. **Middleware as Shared Infrastructure**: Reusable across different workflow types

## 📦 Core Dependencies & Configuration

### 1. Update mix.exs

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  @app :my_app
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      name: "#{@app}",
      archives: [mix_gleam: "~> 0.6.2"],
      compilers: [:gleam] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      erlc_paths: [
        "build/dev/erlang/#{@app}/_gleam_artefacts",
        "build/dev/erlang/#{@app}/build"
      ],
      erlc_include_path: "build/dev/erlang/#{@app}/include",
      prune_code_paths: false,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MyApp.Web.Application, []},
      extra_applications: [:logger, :runtime_tools, :tls_certificate_check]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/my_app/data/support", "test/my_app/web/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core Phoenix
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},

      # Real-time communication
      {:live_state, "~> 0.8.1"},
      {:cors_plug, "~> 3.0"},

      # Authentication
      {:joken, "~> 2.6"},
      {:joken_jwks, "~> 1.7"},
      {:tesla, "~> 1.14"},
      {:hackney, "~> 1.23"},

      # Job processing
      {:oban, "~> 2.19"},

      # LLM integration
      {:magus, "~> 0.2.0"},
      {:langchain, "~> 0.3.2"},
      {:reactor, "~> 0.15.2"},
      {:instructor, "~> 0.1.0"},
      {:typed_struct, "~> 0.3"},

      # Gleam integration
      {:gleam_stdlib, "~> 0.59"},
      {:gleam_json, "~> 2.3.0"},

      # Observability
      {:opentelemetry_exporter, "~> 1.8"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_bandit, "~> 0.2.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_process_propagator, "~> 0.3"},
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry_semantic_conventions, "~> 1.27"},
      {:tls_certificate_check, "~> 1.27"},
      {:prom_ex, "~> 1.11.0"},

      # Frontend build
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},

      # Development
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:tidewave, "~> 0.1", only: :dev},

      # Testing
      {:meck, "~> 1.0", only: :test},
      {:mimic, "~> 1.11.2", only: :test},

      # Code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --trace"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets node build.js"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"],
      check: [
        "compile",
        "format --check-formatted",
        "credo --strict",
        "dialyzer",
        "sobelow --skip --exit",
        "test",
        "docs"
      ]
    ]
  end
end
```

### 2. Application Configuration

Create `config/config.exs`:
```elixir
import Config

# Configure repositories
config :my_app,
  ecto_repos: [MyApp.Data.Repo],
  generators: [context_app: :my_app]

# Configure endpoint
config :my_app, MyApp.Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: MyApp.Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.Data.PubSub,
  secure_browser_headers: %{
    "content-security-policy" =>
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; frame-ancestors 'none';"
  }

# Configure LiveState
config :live_state, otp_app: :my_app

# Configure CORS
config :cors_plug,
  origin: "*",
  methods: [:get, :post, :put, :delete, :options],
  headers: ["content-type"]

# Configure ESBuild
config :esbuild,
  version: "0.18.6",
  default: [
    args: ~w(js/app.tsx --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure JSON library
config :phoenix, :json_library, Jason

# Configure logger
config :logger, :console,
  format: "$time [$level] $message $metadata\n",
  metadata: [:mfa, :pid, :crash_reason, :initial_call, :application]

# Configure Oban
config :my_app, Oban,
  engine: Oban.Engines.Basic,
  repo: MyApp.Data.Repo,
  notifier: Oban.Notifiers.PG,
  peer: false,
  prefix: false,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron, crontab: []},
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)}
  ],
  queues: [
    content_generation: 2,  # Example job queue
    default: 5
  ],
  dispatch_cooldown: 5

# Configure OpenTelemetry
config :opentelemetry, :resource, service: %{name: "my_app"}
config :opentelemetry,
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: System.get_env("OTLP_ENDPOINT")

# Configure Reactor middleware
config :my_app, Reactor.Middleware.OpenTelemetryMiddleware,
  enabled: true,
  span_attributes: [
    service_name: "my_app",
    service_version: "1.0.0"
  ],
  include_arguments: true,
  include_results: true

config :my_app, Reactor.Middleware.StructuredLoggingMiddleware,
  enabled: true,
  log_level: :info,
  include_arguments: true,
  include_results: true,
  max_argument_size: 1000

config :my_app, Reactor.Middleware.TelemetryEventsMiddleware,
  enabled: true,
  event_prefix: [:reactor],
  include_metadata: true

# Import environment configs
import_config "#{config_env()}.exs"
```

## 🗄️ Database & Ecto Setup

### 1. Create Repository

Create `lib/my_app/data/repo.ex`:
```elixir
defmodule MyApp.Data.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.SQLite3

  def init(_type, config) do
    {:ok, Keyword.put(config, :url, System.get_env("DATABASE_URL", "sqlite:///data/my_app.db"))}
  end
end
```

### 2. Core Domain Models

Create `lib/my_app/core/user.ex`:
```elixir
defmodule MyApp.Core.User do
  @moduledoc """
  User domain model representing authenticated users.
  """

  defstruct [:external_id, :username, :email, :created_at]

  @type t :: %__MODULE__{
    external_id: String.t(),
    username: String.t(),
    email: String.t(),
    created_at: DateTime.t()
  }
end
```

Create `lib/my_app/core/session.ex`:
```elixir
defmodule MyApp.Core.Session do
  @moduledoc """
  Collaboration session domain model.
  """

  defstruct [:id, :title, :description, :content, :starting_prompt, :created_at, :status]

  @type status :: :active | :completed | :archived

  @type t :: %__MODULE__{
    id: integer(),
    title: String.t(),
    description: String.t(),
    content: String.t(),
    starting_prompt: String.t(),
    created_at: DateTime.t(),
    status: status()
  }
end
```

> **💡 Domain Tip**: Use **TypedStruct for internal data structures** and **Ecto.EmbeddedSchema for API boundaries**. Always verify struct patterns with explicit pattern matching like `%MyApp.Core.Session{} = session`.

### 3. Data Layer Schemas

Create `lib/my_app/data/session.ex`:
```elixir
defmodule MyApp.Data.Session do
  @moduledoc """
  Ecto schema and context for collaboration sessions.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias MyApp.Data.Repo

  @primary_key {:id, :id, autogenerate: true}
  schema "sessions" do
    field :title, :string
    field :description, :string
    field :content, :string
    field :starting_prompt, :string
    field :status, Ecto.Enum, values: [:active, :completed, :archived], default: :active

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:title, :description, :content, :starting_prompt, :status])
    |> validate_required([:title, :description, :starting_prompt])
    |> validate_length(:title, max: 200)
  end

  def create_session(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def list_sessions_for_ui(limit \\ 50) do
    from(s in __MODULE__,
      where: s.status == :active,
      order_by: [desc: s.inserted_at],
      limit: ^limit,
      select: %{
        id: s.id,
        title: s.title,
        description: s.description,
        created_at: s.inserted_at
      }
    )
    |> Repo.all()
  end

  def get_session!(id) do
    Repo.get!(__MODULE__, id)
  end
end
```

> **💡 Data Layer Tip**: Use **keyword-based queries** like `from(u in User, where: u.age > 18, select: u)` over pipe-based queries. Place Ecto schemas and queries in `MyApp.Data.*` with embedded data access functions.

### 4. Create Migration

```bash
mix ecto.gen.migration create_sessions
```

Edit the migration file:
```elixir
defmodule MyApp.Data.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :title, :string, null: false
      add :description, :text
      add :content, :text
      add :starting_prompt, :text
      add :status, :string, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:sessions, [:status])
    create index(:sessions, [:inserted_at])
  end
end
```

## 🔐 Authentication System

### 1. Guardian Configuration

Create `lib/my_app/web/auth/guardian.ex`:
```elixir
defmodule MyApp.Web.Auth.Guardian do
  @moduledoc """
  Authentication module using Auth0 JWT validation.
  """

  alias MyApp.Core.User

  require Logger

  def verify_and_get_user_info(token) when is_binary(token) do
    with {:ok, claims} <- verify_jwt(token),
         {:ok, user} <- extract_user_from_claims(claims) do
      {:ok, user}
    else
      {:error, reason} ->
        Logger.warning("JWT verification failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp verify_jwt(token) do
    config = Application.get_env(:my_app, __MODULE__.Strategy, [])
    jwks_url = Keyword.get(config, :jwks_url)

    case Joken.verify(token, Joken.Signer.create("RS256", %{"jwks_url" => jwks_url})) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_user_from_claims(%{"sub" => sub} = claims) do
    user = %User{
      external_id: sub,
      username: Map.get(claims, "nickname", sub),
      email: Map.get(claims, "email"),
      created_at: DateTime.utc_now()
    }

    {:ok, user}
  end

  defp extract_user_from_claims(_claims) do
    {:error, "Invalid JWT claims"}
  end
end
```

Create `lib/my_app/web/auth/guardian/strategy.ex`:
```elixir
defmodule MyApp.Web.Auth.Guardian.Strategy do
  @moduledoc """
  Guardian strategy for JWKS fetching and caching.
  """
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Initialize ETS table for JWKS caching
    :ets.new(:jwks_cache, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def get_jwks(jwks_url) do
    case :ets.lookup(:jwks_cache, jwks_url) do
      [{^jwks_url, jwks}] ->
        {:ok, jwks}

      [] ->
        fetch_and_cache_jwks(jwks_url)
    end
  end

  defp fetch_and_cache_jwks(jwks_url) do
    case Tesla.get(jwks_url) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, jwks} ->
            :ets.insert(:jwks_cache, {jwks_url, jwks})
            {:ok, jwks}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

## 🔄 Real-Time Architecture with LiveState

### 1. LiveState Socket

Create `lib/my_app/web/channels/live_state_socket.ex`:
```elixir
defmodule MyApp.Web.LiveStateSocket do
  use Phoenix.Socket

  alias MyApp.Web.{WorkspaceChannel, SessionListChannel, JobManagementChannel}

  channel WorkspaceChannel.channel_name(), WorkspaceChannel
  channel SessionListChannel.channel_name(), SessionListChannel
  channel JobManagementChannel.channel_name(), JobManagementChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: "my_app"
end
```

### 2. Session List Channel

Create `lib/my_app/web/channels/session_list_channel.ex`:
```elixir
defmodule MyApp.Web.SessionListChannel do
  @moduledoc """
  LiveState channel for managing and broadcasting session lists.
  """
  use LiveState.Channel, web_module: MyApp.Web

  alias MyApp.Data.Session
  alias MyApp.Web.Auth.Guardian
  alias MyApp.Web.ChannelInit

  require OpenTelemetry.Tracer

  @channel_name "session_list"

  def channel_name, do: @channel_name

  @impl true
  def init(@channel_name, %{"token" => token}, socket) do
    socket = ChannelInit.assign_channel_id(socket)
    Logger.metadata(request_id: socket.assigns.channel_id)

    OpenTelemetry.Tracer.with_span "live-state.init.#{@channel_name}", %{
      attributes: [{:channel_id, socket.assigns.channel_id}]
    } do
      case Guardian.verify_and_get_user_info(token) do
        {:ok, user} ->
          Logger.info("Authenticated WebSocket connection for user: #{user.username}")

          # Subscribe to session updates
          Phoenix.PubSub.subscribe(MyApp.Data.PubSub, "session_list")

          sessions = Session.list_sessions_for_ui()

          state = %{
            sessions: sessions,
            username: user.username,
            error: nil
          }

          {:ok, state, assign(socket, username: user.username)}

        {:error, reason} ->
          Logger.warning("WebSocket auth failed: #{inspect(reason)}")
          :error
      end
    end
  end

  @impl true
  def handle_event(unmatched_event, payload, state) do
    Logger.warning("Unmatched event: '#{unmatched_event}' with payload '#{inspect(payload)}'")
    {:noreply, state}
  end

  @impl true
  def handle_message({:session_created, %{session: _session}}, state) do
    updated_sessions = Session.list_sessions_for_ui()
    {:noreply, %{state | sessions: updated_sessions}}
  end
end
```

> **💡 LiveState Tip**: **Never mix LiveState patterns with regular Phoenix channel patterns**. Use `{:noreply, state}` pattern and subscribe to PubSub topics in `init/3`. Frontend should use "fire-and-forget" pattern with `pushEvent()` without `await`.

### 3. Channel Initialization Helper

Create `lib/my_app/web/channels/channel_init.ex`:
```elixir
defmodule MyApp.Web.ChannelInit do
  @moduledoc """
  Helper functions for channel initialization.
  """

  def assign_channel_id(socket) do
    channel_id = generate_channel_id()
    Phoenix.Socket.assign(socket, :channel_id, channel_id)
  end

  defp generate_channel_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> String.downcase()
  end
end
```

## ⚙️ Background Job Processing with Oban

> **🎯 Job Architecture Pattern**: Use **job-specific context modules** instead of monolithic modules, implement **data layer separation** with embedded access functions, and use **behavior patterns** for loosely coupled telemetry handlers.

### 1. Job Data Schema

Create `lib/my_app/data/jobs/content_generation_job.ex`:
```elixir
defmodule MyApp.Data.Jobs.ContentGenerationJob do
  @moduledoc """
  Ecto schema for content generation jobs.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias MyApp.Data.Repo

  @primary_key {:id, :id, autogenerate: true}
  schema "content_generation_jobs" do
    field :title, :string
    field :theme, :string
    field :difficulty, :string
    field :status, Ecto.Enum, values: [:pending, :running, :completed, :failed, :cancelled], default: :pending
    field :progress, :integer, default: 0
    field :result, :map
    field :error_message, :string
    field :user_id, :string
    field :oban_job_id, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:title, :theme, :difficulty, :status, :progress, :result, :error_message, :user_id, :oban_job_id])
    |> validate_required([:theme, :difficulty, :user_id])
    |> validate_inclusion(:status, [:pending, :running, :completed, :failed, :cancelled])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def get!(id), do: Repo.get!(__MODULE__, id)
  def get(id), do: Repo.get(__MODULE__, id)

  def get_by_oban_id(oban_job_id) do
    Repo.get_by(__MODULE__, oban_job_id: oban_job_id)
  end

  def update_status(job, attrs) do
    job
    |> changeset(attrs)
    |> Repo.update()
  end

  def list_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    status_filter = Keyword.get(opts, :status)

    query = from(j in __MODULE__,
      where: j.user_id == ^user_id,
      order_by: [desc: j.inserted_at],
      limit: ^limit
    )

    query =
      case status_filter do
        nil -> query
        status -> from(j in query, where: j.status == ^status)
      end

    Repo.all(query)
  end

  def list_for_sidebar(user_id, completed_limit \\ 10) do
    # Get running jobs
    running = from(j in __MODULE__,
      where: j.user_id == ^user_id and j.status in [:pending, :running],
      order_by: [desc: j.inserted_at]
    ) |> Repo.all()

    # Get recent completed jobs
    completed = from(j in __MODULE__,
      where: j.user_id == ^user_id and j.status in [:completed, :failed, :cancelled],
      order_by: [desc: j.inserted_at],
      limit: ^completed_limit
    ) |> Repo.all()

    running ++ completed
  end
end
```

### 2. Job Context Module

Create `lib/my_app/jobs/content_generation_job.ex`:
```elixir
defmodule MyApp.Jobs.ContentGenerationJob do
  @moduledoc """
  Context for managing content generation jobs.
  """

  alias MyApp.Data.Jobs.ContentGenerationJob, as: ContentGenerationJobData
  alias MyApp.LLM.Workers.ContentGenerationWorker

  require Logger

  def create_content_generation_job(attrs) do
    with {:ok, job} <- create_job_record(attrs),
         {:ok, oban_job} <- enqueue_oban_job(job) do
      ContentGenerationJobData.update_status(job, %{oban_job_id: oban_job.id})
    end
  end

  def get_content_generation_job!(id) do
    ContentGenerationJobData.get!(id)
  end

  def get_content_generation_job_by_oban_id(oban_job_id) do
    ContentGenerationJobData.get_by_oban_id(oban_job_id)
  end

  def list_jobs_for_sidebar(user_id, completed_limit \\ 10) do
    ContentGenerationJobData.list_for_sidebar(user_id, completed_limit)
  end

  def update_job_status(job_id, status, attrs \\ %{}) do
    job = ContentGenerationJobData.get!(job_id)
    attrs = Map.put(attrs, :status, status)

    case ContentGenerationJobData.update_status(job, attrs) do
      {:ok, updated_job} ->
        # Broadcast status update
        Phoenix.PubSub.broadcast(
          MyApp.Data.PubSub,
          "job_updates:#{updated_job.user_id}",
          {:job_status_update, %{
            job_id: updated_job.id,
            status: updated_job.status,
            progress: updated_job.progress,
            error_message: updated_job.error_message,
            result: updated_job.result,
            updated_at: updated_job.updated_at
          }}
        )

        {:ok, updated_job}

      error -> error
    end
  end

  def complete_job(job_id, result) do
    update_job_status(job_id, :completed, %{result: result, progress: 100})
  end

  def fail_job(job_id, error_message) do
    update_job_status(job_id, :failed, %{error_message: to_string(error_message)})
  end

  def update_job_progress(job_id, progress) when progress >= 0 and progress <= 100 do
    update_job_status(job_id, :running, %{progress: progress})
  end

  # Private functions

  defp create_job_record(attrs) do
    title = generate_job_title(attrs[:theme], attrs[:difficulty])
    attrs = Map.put(attrs, :title, title)
    ContentGenerationJobData.create(attrs)
  end

  defp enqueue_oban_job(job) do
    job_args = %{
      "job_id" => job.id,
      "theme" => job.theme,
      "difficulty" => job.difficulty,
      "user_id" => job.user_id
    }

    job_args
    |> ContentGenerationWorker.new(meta: %{
      "job_title" => job.title,
      "created_by" => job.user_id
    })
    |> Oban.insert()
  end

  defp generate_job_title(theme, difficulty) do
    "Generating #{difficulty} content: #{theme}"
  end
end
```

### 3. Oban Telemetry Handler

Create `lib/my_app/jobs/oban_telemetry_handler.ex`:
```elixir
defmodule MyApp.Jobs.ObanTelemetryHandler do
  @moduledoc """
  Generic Oban telemetry handler that dispatches to job-specific handlers.
  """

  require Logger

  # Registry of job-specific handlers
  @job_handlers [
    MyApp.Jobs.ContentGenerationJob.TelemetryHandler
  ]

  def attach_handlers do
    :telemetry.attach_many(
      "oban-job-telemetry",
      [
        [:oban, :job, :start],
        [:oban, :job, :stop],
        [:oban, :job, :exception]
      ],
      &handle_event/4,
      %{}
    )

    Logger.info("Attached Oban telemetry handlers")
  end

  def handle_event([:oban, :job, :start], measurements, metadata, _config) do
    dispatch_to_handlers(:handle_job_start, [metadata.job])
  end

  def handle_event([:oban, :job, :stop], measurements, metadata, _config) do
    result = case metadata.state do
      :success -> {:ok, metadata.result}
      :failure -> {:error, metadata.error}
      :cancel -> {:cancelled, metadata.error}
      :discard -> {:discarded, metadata.error}
    end

    dispatch_to_handlers(:handle_job_completion, [metadata.job, result])
  end

  def handle_event([:oban, :job, :exception], measurements, metadata, _config) do
    dispatch_to_handlers(:handle_job_exception, [
      metadata.job,
      metadata.kind,
      metadata.error,
      metadata.stacktrace
    ])
  end

  defp dispatch_to_handlers(function, args) do
    Enum.each(@job_handlers, fn handler ->
      try do
        apply(handler, function, args)
      rescue
        error ->
          Logger.error("Error in job handler #{inspect(handler)}: #{inspect(error)}")
      end
    end)
  end
end
```

## 🤖 LLM Integration with Reactor

### 1. LLM Schemas

Create `lib/my_app/llm/schemas/content.ex`:
```elixir
defmodule MyApp.LLM.Schemas.Content do
  @moduledoc """
  Ecto schema for structured LLM content generation output.
  """
  use Ecto.Schema
  use Instructor.Validator

  @primary_key false
  embedded_schema do
    field :title, :string
    field :description, :string
    field :solution, :string
    field :narrative, :string
    field :difficulty_level, :string
    field :estimated_duration, :string
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> validate_required([:title, :description, :solution, :narrative])
    |> validate_length(:title, max: 200)
    |> validate_length(:description, max: 1000)
  end
end
```

### 2. Reactor Steps

Create `lib/my_app/llm/steps/generate_content_details_step.ex`:
```elixir
defmodule MyApp.LLM.Steps.GenerateContentDetailsStep do
  @moduledoc """
  Reactor step for generating content details using LLM.
  """
  use Reactor.Step

  alias MyApp.LLM.Schemas.Content
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Messages.SystemMessage
  alias LangChain.Messages.UserMessage

  require Logger

  @impl true
  def run(%{theme: theme, difficulty: difficulty}, _context, _step) do
    try do
      Logger.info("Generating content details", %{theme: theme, difficulty: difficulty})

      system_prompt = """
      You are a creative content writer for an interactive collaboration application.
      Generate a compelling content based on the given theme and difficulty level.

      The content should include:
      - An intriguing title
      - A detailed description of the scenario
      - A complete solution explaining what happened
      - An engaging opening narrative that sets the scene
      - Appropriate difficulty level
      - Estimated time to solve

      Make it engaging and suitable for collaborative work.
      """

      user_prompt = """
      Create a #{difficulty} difficulty content with the theme: #{theme}

      The content should be appropriate for the difficulty level:
      - Easy: Simple scenarios with obvious clues
      - Medium: More complex scenarios requiring some deduction
      - Hard: Complex scenarios with multiple red herrings and intricate plots
      """

      messages = [
        SystemMessage.new!(system_prompt),
        UserMessage.new!(user_prompt)
      ]

      case ChatOpenAI.new!()
           |> ChatOpenAI.chat(messages)
           |> Instructor.chat_completion(response_model: Content) do
        {:ok, content} ->
          Logger.info("Successfully generated content", %{title: content.title})
          {:ok, content}

        {:error, reason} ->
          Logger.error("Failed to generate content", %{error: inspect(reason)})
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exception in content generation", %{
          error: Exception.format(:error, e, __STACKTRACE__)
        })
        {:error, e}
    end
  end
end
```

### 3. Reactor Workflow

Create `lib/my_app/llm/reactors/content_generation_reactor.ex`:
```elixir
defmodule MyApp.LLM.Reactors.ContentGenerationReactor do
  @moduledoc """
  Reactor workflow for content generation with comprehensive instrumentation.
  """
  use Reactor

  alias MyApp.LLM.Steps.GenerateContentDetailsStep

  # Enable observability middleware
  middlewares do
    middleware Reactor.Middleware.OpenTelemetryMiddleware
    middleware Reactor.Middleware.StructuredLoggingMiddleware
    middleware Reactor.Middleware.TelemetryEventsMiddleware
  end

  input(:theme)
  input(:difficulty)

  step :generate_content_details, GenerateContentDetailsStep do
    argument(:theme, input(:theme))
    argument(:difficulty, input(:difficulty))
  end

  return(:generate_content_details)
end
```

### 4. Oban Worker

Create `lib/my_app/llm/workers/content_generation_worker.ex`:
```elixir
defmodule MyApp.LLM.Workers.ContentGenerationWorker do
  @moduledoc """
  Oban worker for content generation using Reactor workflow.
  """
  use Oban.Worker, queue: :content_generation, max_attempts: 3

  alias MyApp.LLM.Reactors.ContentGenerationReactor
  alias MyApp.LLM.Schemas.Content
  alias MyApp.Jobs.ContentGenerationJob
  alias MyApp.Data.Session

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"theme" => theme, "difficulty" => difficulty} = args}) do
    job_id = args["job_id"]
    user_id = args["user_id"]

    try do
      # Update job status
      ContentGenerationJob.update_job_status(job_id, :running)

      # Broadcast status update
      Phoenix.PubSub.broadcast(
        MyApp.Data.PubSub,
        "job_updates:#{user_id}",
        {:job_status_update, %{job_id: job_id, status: :running}}
      )

      Logger.info("Starting content generation", %{
        job_id: job_id,
        theme: theme,
        difficulty: difficulty,
        user_id: user_id
      })

      # Update progress
      ContentGenerationJob.update_job_progress(job_id, 10)

      # Run reactor workflow
      case Reactor.run(ContentGenerationReactor, %{theme: theme, difficulty: difficulty}) do
        {:ok, %Content{} = content} ->
          content_data = %{
            title: content.title,
            description: content.description,
            solution: content.solution,
            starting_narrative: content.narrative
          }

          # Create session
          {:ok, session} = Session.create_session(content_data)

          # Complete job
          ContentGenerationJob.complete_job(job_id, content_data)

          # Broadcast completion
          Phoenix.PubSub.broadcast(
            MyApp.Data.PubSub,
            "session_list",
            {:session_created, %{session: session}}
          )

          Phoenix.PubSub.broadcast(
            MyApp.Data.PubSub,
            "job_updates:#{user_id}",
            {:job_status_update, %{
              job_id: job_id,
              status: :completed,
              result: content_data,
              session_id: session.id,
              completed_at: DateTime.utc_now()
            }}
          )

          Logger.info("Content generation completed", %{
            job_id: job_id,
            title: content.title,
            session_id: session.id
          })

          :ok

        {:error, reason} ->
          Logger.error("Content generation failed", %{
            job_id: job_id,
            error: inspect(reason)
          })

          ContentGenerationJob.fail_job(job_id, reason)

          Phoenix.PubSub.broadcast(
            MyApp.Data.PubSub,
            "job_updates:#{user_id}",
            {:job_status_update, %{
              job_id: job_id,
              status: :failed,
              error: inspect(reason),
              failed_at: DateTime.utc_now()
            }}
          )

          {:error, reason}
      end
    rescue
      e ->
        error_msg = Exception.format(:error, e, __STACKTRACE__)

        Logger.error("Content generation worker crashed", %{
          job_id: job_id,
          error: error_msg
        })

        ContentGenerationJob.fail_job(job_id, error_msg)

        Phoenix.PubSub.broadcast(
          MyApp.Data.PubSub,
          "job_updates:#{user_id}",
          {:job_status_update, %{
            job_id: job_id,
            status: :failed,
            error: error_msg,
            failed_at: DateTime.utc_now()
          }}
        )

        {:error, e}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.error("Invalid job arguments", %{args: args})
    {:error, "Missing required arguments"}
  end
end
```

## 🎨 Frontend Setup with React & TypeScript

### 1. Package Configuration

Create `assets/package.json`:
```json
{
  "name": "my-app-frontend",
  "version": "1.0.0",
  "scripts": {
    "build": "node build.js",
    "build-dev": "node build.js --watch",
    "watch": "node build.js --watch"
  },
  "dependencies": {
    "@auth0/auth0-react": "^2.3.0",
    "@chakra-ui/icons": "^2.2.4",
    "@chakra-ui/react": "^2.8.0",
    "@emotion/react": "^11.14.0",
    "@emotion/styled": "^11.14.0",
    "framer-motion": "^6.5.1",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-icons": "^5.5.0",
    "use-live-state": "^0.0.2"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "esbuild": "^0.25.2",
    "typescript": "^5.0.0"
  }
}
```

### 2. Build Configuration

Create `assets/build.js`:
```javascript
import * as esbuild from "esbuild";

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const envPlugin = {
  name: "env",
  setup(build) {
    build.onResolve({ filter: /^env$/ }, (args) => ({
      path: args.path,
      namespace: "env-ns",
    }));

    build.onLoad({ filter: /.*/, namespace: "env-ns" }, () => ({
      contents: JSON.stringify(process.env),
      loader: "json",
    }));
  },
};

let opts = {
  entryPoints: ["js/app.tsx"],
  logLevel: "info",
  bundle: true,
  target: "es2017",
  outdir: "../priv/static/assets",
  external: ["*.css", "fonts/*", "images/*"],
  nodePaths: ["../deps"],
  plugins: [envPlugin],
};

if (deploy) {
  opts = { ...opts, minify: true };
}

if (watch) {
  opts = { ...opts, sourcemap: "inline" };
  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
      console.log("⚡ Watching for changes...");
    })
    .catch((_error) => {
      process.exit(1);
    });
} else {
  esbuild.build(opts);
}
```

### 3. TypeScript Configuration

Create `assets/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": [
    "js/**/*"
  ]
}
```

### 4. Main Application

Create `assets/js/app.tsx`:
```tsx
import React, { useState, useEffect } from "react";
import { createRoot } from "react-dom/client";
import { ChakraProvider, extendTheme, Box } from "@chakra-ui/react";
import { Auth0Provider51 } from "./auth/auth-provider";
import { useAuth } from "./auth/use-auth";
import { ProtectedRoute } from "./auth/protected-route";
import SessionList from "./components/session_list";
import Workspace from "./components/workspace";
import JobQueueSidebar from "./components/job-queue-sidebar";
import LiveState from "use-live-state";

// Terminal-themed Chakra UI theme
const theme = extendTheme({
  colors: {
    brand: {
      50: "#d4ffde",
      500: "#00e63a", // Terminal green
      900: "#001a05",
    },
    terminal: {
      500: "#00e63a",
      600: "#00b32e",
      700: "#008022",
    },
    background: {
      800: "#101418", // Dark background
      900: "#000a02", // Even darker
    },
  },
  fonts: {
    heading: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
    body: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
  },
  styles: {
    global: {
      body: {
        bg: "#000a02",
        color: "#00e63a",
        fontFamily: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
      },
    },
  },
});

// Container components for LiveState management
const SessionListContainer = ({ createLiveState, onSessionSelect, recentSessions }) => {
  const [liveState, setLiveState] = useState(null);
  const [jobManagementState, setJobManagementState] = useState(null);

  useEffect(() => {
    async function createChannels() {
      const sessionChannel = await createLiveState("session_list");
      const jobChannel = await createLiveState("job_management");
      setLiveState(sessionChannel);
      setJobManagementState(jobChannel);
    }
    createChannels();
  }, []);

  if (liveState && jobManagementState) {
    return (
      <SessionList
        socket={liveState}
        jobManagementSocket={jobManagementState}
        onSessionSelect={onSessionSelect}
        recentSessions={recentSessions}
      />
    );
  }
  return <></>;
};

const WorkspaceContainer = ({ createLiveState, sessionId, onBackToList }) => {
  const [liveState, setLiveState] = useState(null);

  useEffect(() => {
    async function createChannel() {
      const channel = await createLiveState(`workspace:${sessionId}`);
      setLiveState(channel);
    }
    createChannel();
  }, []);

  if (liveState) {
    return (
      <Workspace
        socket={liveState}
        sessionId={sessionId}
        onBackToList={onBackToList}
      />
    );
  }
  return <></>;
};

const JobManagementContainer = ({ createLiveState, onSessionCreated }) => {
  const [liveState, setLiveState] = useState(null);

  useEffect(() => {
    async function createChannel() {
      const channel = await createLiveState("job_management");
      setLiveState(channel);
    }
    createChannel();
  }, []);

  if (liveState) {
    return <JobQueueSidebar socket={liveState} onSessionCreated={onSessionCreated} />;
  }
  return <></>;
};

const App = () => {
  const [currentSessionId, setCurrentSessionId] = useState<number | null>(null);
  const [recentSessions, setRecentSessions] = useState<number[]>(() => {
    const stored = localStorage.getItem("recentSessions");
    return stored ? JSON.parse(stored) : [];
  });
  const { user, isAuthenticated, getToken } = useAuth();

  // Create LiveState connection with authentication
  const createLiveState = async (topic: string) => {
    let params = {};

    if (isAuthenticated && user) {
      const token = await getToken();
      if (token) {
        params = { token };
      }
    }

    return new LiveState({
      topic,
      url: "ws://localhost:4000/socket",
      params,
    });
  };

  const handleSessionSelect = (sessionId: number | null) => {
    if (sessionId !== null) {
      const updatedSessions = [
        sessionId,
        ...recentSessions.filter((id) => id !== sessionId),
      ].slice(0, 10);

      setRecentSessions(updatedSessions);
      localStorage.setItem("recentSessions", JSON.stringify(updatedSessions));
    }

    setCurrentSessionId(sessionId);
  };

  const handleBackToList = () => {
    setCurrentSessionId(null);
  };

  const renderMainContent = () => {
    if (currentSessionId === null) {
      return (
        <SessionListContainer
          createLiveState={createLiveState}
          onSessionSelect={handleSessionSelect}
          recentSessions={recentSessions}
        />
      );
    } else {
      return (
        <WorkspaceContainer
          createLiveState={createLiveState}
          sessionId={currentSessionId}
          onBackToList={handleBackToList}
        />
      );
    }
  };

  return (
    <Box position="relative">
      <Box mr="350px">
        {renderMainContent()}
      </Box>

      {isAuthenticated && user && (
        <JobManagementContainer
          createLiveState={createLiveState}
          onSessionCreated={handleSessionSelect}
        />
      )}
    </Box>
  );
};

const rootElement = document.getElementById("root");
const root = createRoot(rootElement!);
root.render(
  <Auth0Provider51>
    <ProtectedRoute>
      <ChakraProvider theme={theme}>
        <App />
      </ChakraProvider>
    </ProtectedRoute>
  </Auth0Provider51>
);
```

### 5. Auth0 Integration

Create `assets/js/auth/auth-provider.tsx`:
```tsx
import React from "react";
import { Auth0Provider } from "@auth0/auth0-react";

interface Auth0Provider51Props {
  children: React.ReactNode;
}

export const Auth0Provider51: React.FC<Auth0Provider51Props> = ({ children }) => {
  const domain = process.env.REACT_APP_AUTH0_DOMAIN || "";
  const clientId = process.env.REACT_APP_AUTH0_CLIENT_ID || "";
  const audience = process.env.REACT_APP_AUTH0_AUDIENCE || "";

  return (
    <Auth0Provider
      domain={domain}
      clientId={clientId}
      authorizationParams={{
        redirect_uri: window.location.origin,
        audience: audience,
      }}
    >
      {children}
    </Auth0Provider>
  );
};
```

Create `assets/js/auth/use-auth.tsx`:
```tsx
import { useAuth0 } from "@auth0/auth0-react";

export const useAuth = () => {
  const {
    user,
    isAuthenticated,
    isLoading,
    loginWithRedirect,
    logout,
    getAccessTokenSilently,
  } = useAuth0();

  const getToken = async () => {
    try {
      return await getAccessTokenSilently();
    } catch (error) {
      console.error("Error getting access token:", error);
      return null;
    }
  };

  return {
    user,
    isAuthenticated,
    isLoading,
    loginWithRedirect,
    logout,
    getToken,
  };
};
```

Create `assets/js/auth/protected-route.tsx`:
```tsx
import React from "react";
import { Center, Spinner, Button, VStack, Text } from "@chakra-ui/react";
import { useAuth } from "./use-auth";

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, isLoading, loginWithRedirect } = useAuth();

  if (isLoading) {
    return (
      <Center h="100vh">
        <Spinner size="xl" color="terminal.500" />
      </Center>
    );
  }

  if (!isAuthenticated) {
    return (
      <Center h="100vh">
        <VStack spacing={4}>
          <Text fontSize="2xl" color="terminal.500">
            🔒 AUTHENTICATION REQUIRED 🔒
          </Text>
          <Button
            onClick={() => loginWithRedirect()}
            colorScheme="terminal"
            size="lg"
          >
            AUTHENTICATE
          </Button>
        </VStack>
      </Center>
    );
  }

  return <>{children}</>;
};
```

## 📊 Observability & Monitoring

### 1. Middleware Implementation

Create `lib/reactor/middleware/utils.ex`:
```elixir
defmodule Reactor.Middleware.Utils do
  @moduledoc """
  Utility functions for reactor middleware.
  """

  def safe_execute(func, fallback) do
    try do
      func.()
    rescue
      e ->
        require Logger
        Logger.warning("Middleware error: #{inspect(e)}")
        fallback
    end
  end

  def get_config(module, key, default) do
    :my_app
    |> Application.get_env(module, [])
    |> Keyword.get(key, default)
  end

  def get_reactor_name(context) do
    Map.get(context, :reactor_name, "unknown")
  end

  def calculate_duration(context, start_time_key) do
    case Map.get(context, start_time_key) do
      nil -> 0
      start_time -> System.monotonic_time() - start_time
    end
  end

  def store_step_start_time(step_name) do
    Process.put({:step_start_time, step_name}, System.monotonic_time())
  end

  def calculate_step_duration(step, _context) do
    case Process.get({:step_start_time, step.name}) do
      nil -> 0
      start_time -> System.monotonic_time() - start_time
    end
  end

  def build_error_info(error, module) do
    %{
      type: error_type(error),
      message: error_message(error),
      module: module
    }
  end

  def error_type(error) when is_atom(error), do: error
  def error_type(%{__struct__: struct}), do: struct
  def error_type(_), do: :unknown_error

  def error_message(error) when is_binary(error), do: error
  def error_message(%{message: message}), do: message
  def error_message(error), do: inspect(error)

  def result_type(result) when is_map(result), do: :map
  def result_type(result) when is_list(result), do: :list
  def result_type(result) when is_binary(result), do: :string
  def result_type(result) when is_atom(result), do: :atom
  def result_type(_), do: :unknown
end
```

### 2. Docker Observability Stack

Create `docker-compose.observability.yml`:
```yaml
version: '3.8'

services:
  # OpenTelemetry Collector
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./observability/otel-collector.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC receiver
      - "4318:4318"   # OTLP HTTP receiver
    depends_on:
      - tempo

  # Tempo for distributed tracing
  tempo:
    image: grafana/tempo:latest
    command: [ "-config.file=/etc/tempo.yaml" ]
    volumes:
      - ./observability/tempo/tempo.yaml:/etc/tempo.yaml
      - tempo-data:/tmp/tempo
    ports:
      - "3200:3200"   # Tempo
      - "4317"        # OTLP gRPC

  # Prometheus for metrics
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    volumes:
      - ./observability/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"

  # Loki for logs
  loki:
    image: grafana/loki:latest
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./observability/loki/loki-config.yaml:/etc/loki/local-config.yaml
      - loki-data:/loki
    ports:
      - "3100:3100"

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./observability/grafana/datasources:/etc/grafana/provisioning/datasources
      - ./observability/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"

volumes:
  tempo-data:
  prometheus-data:
  loki-data:
  grafana-data:
```

### 3. Observability Configuration Files

Create observability configuration:

```bash
mkdir -p observability/{tempo,prometheus,loki,grafana/{datasources,dashboards}}
```

Create `observability/tempo/tempo.yaml`:
```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

ingester:
  trace_idle_period: 10s
  max_block_bytes: 1_000_000
  max_block_duration: 5m

compactor:
  compaction:
    compaction_window: 1h
    max_block_bytes: 100_000_000
    block_retention: 1h
    compacted_block_retention: 10m

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/traces
    wal:
      path: /tmp/tempo/wal
    pool:
      max_workers: 100
      queue_depth: 10000
```

## 🚀 Deployment Configuration

### 1. Create Release Configuration

Create `config/runtime.exs`:
```elixir
import Config

# Configure database
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :my_app, MyApp.Data.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # Configure endpoint
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyApp.Web.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure Auth0
  config :my_app, MyApp.Web.Auth.Guardian.Strategy,
    jwks_url: System.get_env("APP_AUTH0_JWKS_URL")

  # Configure OpenTelemetry
  config :opentelemetry_exporter,
    otlp_endpoint: System.get_env("OTLP_ENDPOINT")
end
```

### 2. Docker Configuration

Create `Dockerfile`:
```dockerfile
# Build stage
FROM hexpm/elixir:1.18.3-erlang-27.2-alpine-3.21.0 AS build

# Install build dependencies
RUN apk add --no-cache build-base git npm

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before we compile dependencies
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy priv and lib
COPY priv priv
COPY lib lib

# Copy assets
COPY assets assets

# Install npm dependencies and build assets
WORKDIR /app/assets
RUN npm install
RUN npm run build
WORKDIR /app

# Compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Assemble the release
RUN mix release

# App stage
FROM alpine:3.21.0 AS app

RUN apk add --no-cache openssl ncurses-libs libstdc++

ENV USER="elixir"

WORKDIR "/home/$USER/app"

# Create user
RUN addgroup -g 1000 -S "$USER" && \
    adduser -s /bin/sh -u 1000 -G "$USER" -h "/home/$USER" -D "$USER" && \
    su "$USER"

# Copy the release
COPY --from=build --chown="$USER":"$USER" /app/_build/prod/rel/my_app ./

USER "$USER"

# Set environment
ENV HOME="/home/$USER"

# Expose port
EXPOSE 4000

CMD ["bin/my_app", "start"]
```

## 🧪 Testing Strategy

### 1. Test Configuration

Create `test/test_helper.exs`:
```elixir
# Start testing dependencies
Mimic.copy(Tesla)
Mimic.copy(OpenTelemetry.Tracer)

ExUnit.start()

# Create test database
Ecto.Adapters.SQL.Sandbox.mode(MyApp.Data.Repo, :manual)
```

### 2. Data Case Helper

Create `test/my_app/data/support/data_case.ex`:
```elixir
defmodule MyApp.Data.DataCase do
  @moduledoc """
  Test helpers for data layer tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Data.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.Data.DataCase
    end
  end

  setup tags do
    MyApp.Data.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Data.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
```

### 3. LiveState Channel Test Helper

Create `test/my_app/web/support/live_state_channel_case.ex`:
```elixir
defmodule MyApp.Web.LiveStateChannelCase do
  @moduledoc """
  Test helpers for LiveState channels.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import MyApp.Web.LiveStateChannelCase

      alias MyApp.Web.LiveStateSocket

      @endpoint MyApp.Web.Endpoint
    end
  end

  setup tags do
    MyApp.Data.DataCase.setup_sandbox(tags)
    :ok
  end

  def create_mock_token do
    claims = %{
      "sub" => "test_user_123",
      "nickname" => "testuser",
      "email" => "test@example.com"
    }

    Joken.encode_and_sign(claims, Joken.Signer.create("HS256", "test_secret"))
  end
end
```

### 4. Sample Tests

Create `test/my_app/jobs/content_generation_job_test.exs`:
```elixir
defmodule MyApp.Jobs.ContentGenerationJobTest do
  use MyApp.Data.DataCase

  alias MyApp.Jobs.ContentGenerationJob

  describe "create_content_generation_job/1" do
    test "creates job and enqueues Oban job" do
      attrs = %{
        theme: "creative writing",
        difficulty: "medium",
        user_id: "test_user_123"
      }

      assert {:ok, job} = ContentGenerationJob.create_content_generation_job(attrs)
      assert job.theme == "creative writing"
      assert job.status == :pending
      assert job.oban_job_id != nil
    end

    test "generates appropriate job title" do
      attrs = %{
        theme: "technical documentation",
        difficulty: "hard",
        user_id: "test_user_123"
      }

      assert {:ok, job} = ContentGenerationJob.create_content_generation_job(attrs)
      assert job.title == "Generating hard content: technical documentation"
    end
  end

  describe "update_job_status/3" do
    test "updates status and broadcasts change" do
      {:ok, job} = ContentGenerationJob.create_content_generation_job(%{
        theme: "test",
        difficulty: "easy",
        user_id: "test_user"
      })

      # Subscribe to PubSub for testing
      Phoenix.PubSub.subscribe(MyApp.Data.PubSub, "job_updates:test_user")

      assert {:ok, updated_job} = ContentGenerationJob.update_job_status(job.id, :running, %{progress: 50})
      assert updated_job.status == :running
      assert updated_job.progress == 50

      # Verify broadcast
      assert_receive {:job_status_update, %{job_id: job_id, status: :running}}
      assert job_id == job.id
    end
  end
end
```

## 🔄 Development Workflow

### 1. Setup Commands

Create a `Justfile` (or `Makefile`) for common commands:

```justfile
# List all commands
default:
    @just --list

# Setup development environment
setup:
    mix setup
    npm install --prefix assets

# Start development server
dev:
    mix phx.server

# Start with observability stack
dev-full:
    docker-compose -f docker-compose.observability.yml up -d
    mix phx.server

# Run tests
test:
    mix test

# Run tests with coverage
test-cov:
    mix test --cover

# Run code quality checks
check:
    mix check

# Format code
fmt:
    mix format
    cd assets && npm run prettier

# Reset database
reset-db:
    mix ecto.reset

# Generate new migration
migrate name:
    mix ecto.gen.migration {{name}}

# Run migrations
migrate-up:
    mix ecto.migrate

# Build release
build:
    docker build -t my_app:latest .

# Deploy to production
deploy: build
    docker tag my_app:latest my_app:$(git rev-parse --short HEAD)
    # Add your deployment commands here
```

### 2. Development Commands

```bash
# Initial setup
just setup

# Start development (basic)
just dev

# Start with full observability stack
just dev-full

# Run tests
just test

# Check code quality (includes format, credo, dialyzer, sobelow, tests, docs)
just check

# Reset database when needed
just reset-db
```

> **💡 Development Tip**: Use `mix test && mix check` after generating lots of changes to check both Elixir and React code for errors and quality. Use `mix format` to fix formatting errors. When adding new dependencies, always use `mix hex.info <package>` to find the latest version.

### 3. Git Hooks

Create `.gitignore`:
```gitignore
# Elixir
/_build
/deps
/*.ez
/priv/static/assets/

# Database
*.db
*.db-*

# Environment
.env
.env.*

# Logs
*.log

# Node
node_modules/
npm-debug.log*

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Observability data
observability/data/
```

### 4. Development Instructions (CLAUDE.md)

Create `CLAUDE.md` with your project's development instructions:
```markdown
# Development Instructions

## Tools & Dependencies
- Use `mix hex.info <package>` to find latest versions when adding dependencies
- Use `mix test && mix check` command after making changes
- Prefer command `git ls-files -z | xargs -0 sed -i -e 's/FROM_A/TO_B/g'` for batch renaming
- Use LiveState channels for real-time features
- Use Reactor for complex workflows
- Use Oban for background jobs

## Architecture Patterns
- Job-specific context modules in `MyApp.Jobs.*`
- Data layer separation in `MyApp.Data.*`
- Real-time updates via PubSub + LiveState
- Observability via middleware
- Use plural form for context modules, singular for schema modules
- Organize reactors and steps in non-hierarchical folders for composability

## Data & Type Safety
- Define API data structures using Ecto.EmbeddedSchema with typespecs
- Define internal structures using TypedStruct
- Always verify struct patterns with explicit pattern matching
- Use keyword-based queries over pipe-based queries
- User struct uses `external_id` field (from Auth0), not `id`

## LLM Integration
- Use Instructor for structured LLM outputs
- Always use Ecto.Schema with Instructor for structured outputs
- Wrap step `run` implementations with try/rescue for error handling

## LiveState Usage
- LiveState channels work differently from regular Phoenix channels
- Prefer `{:noreply, state}` pattern
- Use `handle_message/2` for PubSub messages, not `handle_info/2`
- Subscribe to PubSub topics in `init/3`
- Frontend: use "fire-and-forget" pattern with `pushEvent()` without `await`

## Testing
- Use `MyApp.Data.DataCase` for data tests
- Use `MyApp.Web.LiveStateChannelCase` for channel tests
- Use mimic for mocking if needed, but avoid unless necessary
- Test continuously during refactoring
- Mock external APIs and assume isolated test environment

## Code Style
- Follow existing patterns for new features
- Use explicit struct patterns for type safety
- Add comprehensive error handling and logging
- Use `dbg/1` for debugging: Add `|> dbg` entries around error areas
- Use relative imports in React rather than absolute paths with `@/`
```

> **🎯 Key Lesson**: This CLAUDE.md serves as your project's development bible. Update it as you learn new patterns and encounter specific challenges in your domain.

## 🎯 Best Practices & Key Patterns

### 🏗️ Architecture Patterns

#### Job Architecture Pattern
- **Scalable job organization**: Use job-specific context modules (`MyApp.Jobs.ContentGenerationJob`) instead of a monolithic `MyApp.Jobs` module
- **Data layer separation**: Place Ecto schemas and queries in `MyApp.Data.Jobs.*` with embedded data access functions
- **Loosely coupled telemetry**: Use behavior pattern (`MyApp.Jobs.JobHandler`) for job-specific telemetry handlers
- **Registry-based dispatch**: Generic `ObanTelemetryHandler` dispatches to job-specific handlers via `@job_handlers` list
- **Adding new job types**: Only requires creating new context module, telemetry handler, data schema, and adding to registry - zero modification of existing jobs

#### Job-to-Session Integration Pattern
- **Unified creation workflows**: Use job-based systems for all entity creation to ensure consistency and async processing
- **Automatic session creation**: Workers should create persistent entities after successful job completion
- **Multi-channel broadcasting**: Use PubSub to broadcast completion events to multiple channels
- **Session access integration**: Completed jobs should automatically make created entities accessible

### 🔄 Real-Time Architecture
- **Use PubSub for broadcasting** updates between backend processes
- **Subscribe to PubSub** in LiveState channel `init/3` for real-time updates
- **Enhanced context functions** should broadcast status changes for seamless real-time experience

### 🔧 Development Patterns

#### Data Structure & Type Safety
- **Always verify struct patterns**: Use explicit pattern matching like `%Reactor.Step{} = step`
- **Understand library data structures**: Before working with external library data, verify the actual structure (lists vs maps, field names)
- **Handle argument structures correctly**: Step arguments are lists of `%Reactor.Argument{}` structs, not maps
- **Use appropriate functions**: Use `length/1` for lists, `map_size/1` for maps - don't mix them up
- **Check User struct fields**: User struct uses `external_id` field (from Auth0), not `id`

#### Workflow Patterns
- **Use Reactor** for composable workflows that form process DAGs
- **Split each reactor and step** into its own module in non-hierarchical folders for better composability
- **Always wrap step `run` implementation** with `try do .. rescue` logging stacktrace and reraising
- **Use context** to pass read-only data through steps
- **Centralize shared utilities**: Create shared utility middleware modules to avoid code duplication

#### Testing Patterns
- **Test continuously during refactoring**: Run `mix test` frequently during large refactoring
- **Use real execution for integration tests**: Use actual library execution (e.g., `Reactor.run/2`) rather than mocking
- **Verify function arity changes**: When changing function signatures, ensure all callers are updated
- **Use mimic for mocking** if needed, but avoid mocking unless really necessary

### 📱 Frontend Patterns

#### LiveState Navigation Patterns
- **Automatic navigation from job completion**: Use job completion events to trigger automatic entity access
- **Navigation loop prevention**: Track processed entity IDs in component state to prevent infinite loops
- **State-driven UX**: Let job completion automatically guide user to created content
- **Cross-channel coordination**: Job management and entity list channels should coordinate

#### React Patterns
- **Use relative imports** (`../hooks/use-something`) rather than absolute paths with `@/` to avoid build issues
- **Create container components** that manage LiveState socket creation
- **Pass sockets as props** to child components
- **Use kebab-case** for file names
- **Prefer types over interfaces**

### 🐛 Debugging Tips
- **Use `dbg/1`** to debug code: Add `|> dbg` entries around error areas
- **RunStepError** indicates an error within the step's `run` function - sprinkle `dbg` around to narrow down
- **Check middleware errors**: Look for "Middleware error" logs for safe_execute failures

### 🚀 Performance Tips
- **Prefer keyword-based queries** over pipe-based queries
- **Use batch similar changes**: Use sed commands for repetitive updates
- **Avoid complex alias configurations**: Use simple, explicit paths in frontend builds

## 🎯 Next Steps

### 1. Core Features to Implement

1. **Collaboration System**
   - Content management
   - Activity logs
   - User contributions

2. **Workflow Logic**
   - Session state management
   - Real-time features
   - Progress tracking

3. **Advanced LLM Features**
   - Dynamic content generation
   - Adaptive processing
   - Personalized responses

### 2. Performance Optimizations

1. **Database Optimization**
   - Add appropriate indexes
   - Implement query optimization
   - Add database connection pooling

2. **Frontend Performance**
   - Implement code splitting
   - Add service worker for caching
   - Optimize bundle size

3. **Real-time Optimization**
   - Implement presence tracking
   - Add rate limiting
   - Optimize PubSub usage

### 3. Production Readiness

1. **Security**
   - Add CSRF protection
   - Implement rate limiting
   - Add input validation

2. **Monitoring**
   - Set up alerts
   - Add health checks
   - Implement log aggregation

3. **Scaling**
   - Add load balancing
   - Implement clustering
   - Add CDN integration

This comprehensive guide provides a complete foundation for building a sophisticated real-time collaborative application with modern web technologies, proper observability, and production-ready patterns.

## 🎨 Optional Gleam Integration

### Why Use Gleam?

Gleam brings functional programming benefits and compile-time type safety to Elixir applications. While entirely optional, it's particularly valuable for:

- **Complex State Management**: Model intricate collaboration states with algebraic data types
- **Type Safety**: Catch errors at compile time rather than runtime
- **Functional Patterns**: Leverage pattern matching and immutability for cleaner state transitions
- **Documentation**: Self-documenting code through expressive type signatures

### When to Consider Gleam Integration

✅ **Good Use Cases:**
- Complex state machines (session states, user permissions, workflow statuses)
- Data transformation pipelines with multiple steps
- Type-safe parsing and validation of external data
- Mathematical computations or business rule engines
- Shared type definitions between frontend and backend

❌ **When to Skip:**
- Simple CRUD operations
- Basic Phoenix controllers and views
- Standard database interactions
- Small applications with minimal state complexity

### Setting Up Gleam Integration

#### 1. Project Configuration

The `mix.exs` file is already configured with Gleam support:

```elixir
def project do
  [
    archives: [mix_gleam: "~> 0.6.2"],
    compilers: [:gleam] ++ Mix.compilers(),
    erlc_paths: [
      "build/dev/erlang/#{@app}/_gleam_artefacts",
      "build/dev/erlang/#{@app}/build"
    ],
    # ... rest of config
  ]
end

defp deps do
  [
    # Gleam integration
    {:gleam_stdlib, "~> 0.59"},
    {:gleam_json, "~> 2.3.0"},
    # ... other deps
  ]
end
```

#### 2. Create Gleam Project Structure

```bash
# Initialize Gleam in your project
cd gleam_state
cat > gleam.toml << 'EOF'
name = "my_app_gleam"
version = "1.0.0"
description = "Type-safe state models for MyApp"
licences = ["Apache-2.0"]
repository = { type = "github", user = "yourusername", repo = "my_app" }

[dependencies]
gleam_stdlib = ">= 0.59.0 and < 1.0.0"
gleam_json = ">= 2.3.0 and < 3.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
EOF

# Create source directories
mkdir -p src/{types,state,utils}
```

### Practical Gleam Examples

#### 1. Session State Management

Create `gleam_state/src/state/session_state.gleam`:

```gleam
import gleam/json
import gleam/result
import gleam/string
import gleam/list

// Define session status types
pub type SessionStatus {
  Active
  Paused
  Completed
  Archived
}

// Define user role in session
pub type UserRole {
  Moderator
  Participant
  Observer
}

// Define session state
pub type SessionState {
  SessionState(
    id: String,
    title: String,
    status: SessionStatus,
    participants: List(Participant),
    content: String,
    created_at: String,
    updated_at: String,
  )
}

pub type Participant {
  Participant(
    user_id: String,
    username: String,
    role: UserRole,
    joined_at: String,
    active: Bool,
  )
}

// State transition functions
pub fn activate_session(session: SessionState) -> SessionState {
  SessionState(..session, status: Active, updated_at: current_timestamp())
}

pub fn add_participant(
  session: SessionState,
  user_id: String,
  username: String,
  role: UserRole,
) -> SessionState {
  let participant = Participant(
    user_id: user_id,
    username: username,
    role: role,
    joined_at: current_timestamp(),
    active: True,
  )
  
  SessionState(
    ..session,
    participants: [participant, ..session.participants],
    updated_at: current_timestamp(),
  )
}

pub fn remove_participant(
  session: SessionState,
  user_id: String,
) -> SessionState {
  let updated_participants = 
    list.filter(session.participants, fn(p) { p.user_id != user_id })
  
  SessionState(
    ..session,
    participants: updated_participants,
    updated_at: current_timestamp(),
  )
}

pub fn update_content(session: SessionState, new_content: String) -> SessionState {
  SessionState(
    ..session,
    content: new_content,
    updated_at: current_timestamp(),
  )
}

// Validation functions
pub fn is_valid_session(session: SessionState) -> Bool {
  !string.is_empty(session.id) 
    && !string.is_empty(session.title)
    && list.length(session.participants) > 0
}

pub fn can_user_modify(session: SessionState, user_id: String) -> Bool {
  case find_participant(session, user_id) {
    Ok(participant) -> participant.role == Moderator
    Error(_) -> False
  }
}

pub fn find_participant(
  session: SessionState,
  user_id: String,
) -> Result(Participant, String) {
  case list.find(session.participants, fn(p) { p.user_id == user_id }) {
    Ok(participant) -> Ok(participant)
    Error(_) -> Error("Participant not found")
  }
}

// JSON serialization
pub fn session_to_json(session: SessionState) -> String {
  json.object([
    #("id", json.string(session.id)),
    #("title", json.string(session.title)),
    #("status", status_to_json(session.status)),
    #("participants", json.array(session.participants, participant_to_json)),
    #("content", json.string(session.content)),
    #("created_at", json.string(session.created_at)),
    #("updated_at", json.string(session.updated_at)),
  ])
  |> json.to_string
}

fn status_to_json(status: SessionStatus) -> json.Json {
  case status {
    Active -> json.string("active")
    Paused -> json.string("paused")
    Completed -> json.string("completed")
    Archived -> json.string("archived")
  }
}

fn participant_to_json(participant: Participant) -> json.Json {
  json.object([
    #("user_id", json.string(participant.user_id)),
    #("username", json.string(participant.username)),
    #("role", role_to_json(participant.role)),
    #("joined_at", json.string(participant.joined_at)),
    #("active", json.bool(participant.active)),
  ])
}

fn role_to_json(role: UserRole) -> json.Json {
  case role {
    Moderator -> json.string("moderator")
    Participant -> json.string("participant")
    Observer -> json.string("observer")
  }
}

// Helper function (would be imported from a time module)
external fn current_timestamp() -> String =
  "erlang" "system_time" "second"
```

#### 2. Content Generation State

Create `gleam_state/src/state/content_generation.gleam`:

```gleam
import gleam/json
import gleam/result
import gleam/list
import gleam/option.{type Option, None, Some}

// Define generation status
pub type GenerationStatus {
  Pending
  InProgress(step: String, progress: Float)
  Completed(result: GeneratedContent)
  Failed(error: String)
}

// Define generated content
pub type GeneratedContent {
  GeneratedContent(
    title: String,
    description: String,
    narrative: String,
    solution: String,
    difficulty: Difficulty,
    estimated_duration: String,
  )
}

pub type Difficulty {
  Easy
  Medium
  Hard
}

// Define generation job state
pub type ContentGenerationJob {
  ContentGenerationJob(
    id: String,
    user_id: String,
    theme: String,
    difficulty: Difficulty,
    status: GenerationStatus,
    created_at: String,
    updated_at: String,
    metadata: Option(JobMetadata),
  )
}

pub type JobMetadata {
  JobMetadata(
    model: String,
    tokens_used: Int,
    generation_time_ms: Int,
  )
}

// State transition functions
pub fn start_generation(job: ContentGenerationJob) -> ContentGenerationJob {
  ContentGenerationJob(
    ..job,
    status: InProgress("initializing", 0.0),
    updated_at: current_timestamp(),
  )
}

pub fn update_progress(
  job: ContentGenerationJob,
  step: String,
  progress: Float,
) -> ContentGenerationJob {
  ContentGenerationJob(
    ..job,
    status: InProgress(step, progress),
    updated_at: current_timestamp(),
  )
}

pub fn complete_generation(
  job: ContentGenerationJob,
  content: GeneratedContent,
  metadata: JobMetadata,
) -> ContentGenerationJob {
  ContentGenerationJob(
    ..job,
    status: Completed(content),
    metadata: Some(metadata),
    updated_at: current_timestamp(),
  )
}

pub fn fail_generation(
  job: ContentGenerationJob,
  error: String,
) -> ContentGenerationJob {
  ContentGenerationJob(
    ..job,
    status: Failed(error),
    updated_at: current_timestamp(),
  )
}

// Query functions
pub fn is_job_running(job: ContentGenerationJob) -> Bool {
  case job.status {
    InProgress(_, _) -> True
    _ -> False
  }
}

pub fn is_job_completed(job: ContentGenerationJob) -> Bool {
  case job.status {
    Completed(_) -> True
    _ -> False
  }
}

pub fn get_progress(job: ContentGenerationJob) -> Float {
  case job.status {
    InProgress(_, progress) -> progress
    Completed(_) -> 100.0
    _ -> 0.0
  }
}

pub fn get_current_step(job: ContentGenerationJob) -> String {
  case job.status {
    Pending -> "pending"
    InProgress(step, _) -> step
    Completed(_) -> "completed"
    Failed(_) -> "failed"
  }
}

// JSON serialization
pub fn job_to_json(job: ContentGenerationJob) -> String {
  json.object([
    #("id", json.string(job.id)),
    #("user_id", json.string(job.user_id)),
    #("theme", json.string(job.theme)),
    #("difficulty", difficulty_to_json(job.difficulty)),
    #("status", status_to_json(job.status)),
    #("created_at", json.string(job.created_at)),
    #("updated_at", json.string(job.updated_at)),
    #("metadata", metadata_to_json(job.metadata)),
  ])
  |> json.to_string
}

fn status_to_json(status: GenerationStatus) -> json.Json {
  case status {
    Pending -> 
      json.object([
        #("type", json.string("pending")),
      ])
    
    InProgress(step, progress) ->
      json.object([
        #("type", json.string("in_progress")),
        #("step", json.string(step)),
        #("progress", json.float(progress)),
      ])
    
    Completed(content) ->
      json.object([
        #("type", json.string("completed")),
        #("content", content_to_json(content)),
      ])
    
    Failed(error) ->
      json.object([
        #("type", json.string("failed")),
        #("error", json.string(error)),
      ])
  }
}

fn content_to_json(content: GeneratedContent) -> json.Json {
  json.object([
    #("title", json.string(content.title)),
    #("description", json.string(content.description)),
    #("narrative", json.string(content.narrative)),
    #("solution", json.string(content.solution)),
    #("difficulty", difficulty_to_json(content.difficulty)),
    #("estimated_duration", json.string(content.estimated_duration)),
  ])
}

fn difficulty_to_json(difficulty: Difficulty) -> json.Json {
  case difficulty {
    Easy -> json.string("easy")
    Medium -> json.string("medium")
    Hard -> json.string("hard")
  }
}

fn metadata_to_json(metadata: Option(JobMetadata)) -> json.Json {
  case metadata {
    None -> json.null()
    Some(meta) ->
      json.object([
        #("model", json.string(meta.model)),
        #("tokens_used", json.int(meta.tokens_used)),
        #("generation_time_ms", json.int(meta.generation_time_ms)),
      ])
  }
}

external fn current_timestamp() -> String =
  "erlang" "system_time" "second"
```

#### 3. Elixir Bridge Module

Create `lib/my_app/gleam/my_app_gleam.ex`:

```elixir
defmodule MyApp.Gleam do
  @moduledoc """
  Bridge module for integrating Gleam state models with Elixir code.
  
  This module provides a clean interface for using Gleam's type-safe
  state management functions from Elixir code.
  """

  # Session state functions
  def create_session_state(params) do
    :session_state.new_session(
      params["id"],
      params["title"],
      params["created_at"] || DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  def add_participant_to_session(session_state, user_id, username, role) do
    gleam_role = map_role_to_gleam(role)
    :session_state.add_participant(session_state, user_id, username, gleam_role)
  end

  def activate_session(session_state) do
    :session_state.activate_session(session_state)
  end

  def update_session_content(session_state, content) do
    :session_state.update_content(session_state, content)
  end

  def session_to_map(session_state) do
    json_string = :session_state.session_to_json(session_state)
    Jason.decode!(json_string)
  end

  # Content generation functions
  def create_content_job(params) do
    :content_generation.new_job(
      params["id"],
      params["user_id"],
      params["theme"],
      map_difficulty_to_gleam(params["difficulty"]),
      params["created_at"] || DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  def start_content_generation(job_state) do
    :content_generation.start_generation(job_state)
  end

  def update_job_progress(job_state, step, progress) do
    :content_generation.update_progress(job_state, step, progress)
  end

  def complete_content_job(job_state, content_data, metadata \\ %{}) do
    gleam_content = map_content_to_gleam(content_data)
    gleam_metadata = map_metadata_to_gleam(metadata)
    :content_generation.complete_generation(job_state, gleam_content, gleam_metadata)
  end

  def fail_content_job(job_state, error) do
    :content_generation.fail_generation(job_state, to_string(error))
  end

  def job_to_map(job_state) do
    json_string = :content_generation.job_to_json(job_state)
    Jason.decode!(json_string)
  end

  def is_job_completed?(job_state) do
    :content_generation.is_job_completed(job_state)
  end

  def get_job_progress(job_state) do
    :content_generation.get_progress(job_state)
  end

  # Private helper functions
  defp map_role_to_gleam("moderator"), do: {:moderator}
  defp map_role_to_gleam("participant"), do: {:participant}
  defp map_role_to_gleam("observer"), do: {:observer}
  defp map_role_to_gleam(_), do: {:participant}

  defp map_difficulty_to_gleam("easy"), do: {:easy}
  defp map_difficulty_to_gleam("medium"), do: {:medium}
  defp map_difficulty_to_gleam("hard"), do: {:hard}
  defp map_difficulty_to_gleam(_), do: {:medium}

  defp map_content_to_gleam(content_data) do
    {:generated_content,
     content_data["title"] || "",
     content_data["description"] || "",
     content_data["narrative"] || "",
     content_data["solution"] || "",
     map_difficulty_to_gleam(content_data["difficulty"]),
     content_data["estimated_duration"] || ""}
  end

  defp map_metadata_to_gleam(metadata) do
    {:job_metadata,
     metadata["model"] || "gpt-4",
     metadata["tokens_used"] || 0,
     metadata["generation_time_ms"] || 0}
  end
end
```

### Integration Patterns

#### 1. Using Gleam in LiveState Channels

```elixir
defmodule MyApp.Web.SessionChannel do
  use LiveState.Channel, web_module: MyApp.Web
  
  alias MyApp.Gleam

  @impl true
  def init(topic, params, socket) do
    # Initialize session state using Gleam
    session_state = Gleam.create_session_state(%{
      "id" => extract_session_id(topic),
      "title" => params["title"] || "New Session"
    })
    
    state = %{
      session_state: session_state,
      participants: []
    }
    
    {:ok, state, socket}
  end

  @impl true
  def handle_event("join_session", %{"user_id" => user_id, "username" => username}, state) do
    # Use Gleam to safely add participant
    updated_session = Gleam.add_participant_to_session(
      state.session_state,
      user_id,
      username,
      "participant"
    )
    
    updated_state = %{state | session_state: updated_session}
    
    # Broadcast the update
    Phoenix.PubSub.broadcast(
      MyApp.Data.PubSub,
      "session:#{extract_session_id(topic)}",
      {:participant_joined, Gleam.session_to_map(updated_session)}
    )
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, state) do
    updated_session = Gleam.update_session_content(state.session_state, content)
    updated_state = %{state | session_state: updated_session}
    
    {:noreply, updated_state}
  end
end
```

#### 2. Using Gleam in Oban Workers

```elixir
defmodule MyApp.LLM.Workers.ContentGenerationWorker do
  use Oban.Worker, queue: :content_generation

  alias MyApp.Gleam
  alias MyApp.Jobs.ContentGenerationJob

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Initialize job state with Gleam
    job_state = Gleam.create_content_job(%{
      "id" => args["job_id"],
      "user_id" => args["user_id"],
      "theme" => args["theme"],
      "difficulty" => args["difficulty"]
    })

    # Start generation
    job_state = Gleam.start_content_generation(job_state)
    broadcast_job_update(job_state, args["user_id"])

    try do
      # Update progress through generation steps
      job_state = Gleam.update_job_progress(job_state, "generating_title", 25.0)
      broadcast_job_update(job_state, args["user_id"])

      # ... LLM generation logic ...

      job_state = Gleam.update_job_progress(job_state, "generating_content", 75.0)
      broadcast_job_update(job_state, args["user_id"])

      # Complete with results
      content_data = %{
        "title" => generated_title,
        "description" => generated_description,
        # ... other fields
      }

      metadata = %{
        "model" => "gpt-4",
        "tokens_used" => 1500,
        "generation_time_ms" => 5000
      }

      completed_job = Gleam.complete_content_job(job_state, content_data, metadata)
      broadcast_job_update(completed_job, args["user_id"])

      :ok
    rescue
      error ->
        failed_job = Gleam.fail_content_job(job_state, inspect(error))
        broadcast_job_update(failed_job, args["user_id"])
        {:error, error}
    end
  end

  defp broadcast_job_update(job_state, user_id) do
    job_data = Gleam.job_to_map(job_state)
    
    Phoenix.PubSub.broadcast(
      MyApp.Data.PubSub,
      "job_updates:#{user_id}",
      {:job_status_update, job_data}
    )
  end
end
```

### Benefits of This Integration

#### 1. **Type Safety at Compile Time**
```gleam
// This will fail to compile if types don't match
pub fn invalid_example(session: SessionState) -> UserRole {
  session.status  // Compile error: SessionStatus ≠ UserRole
}
```

#### 2. **Exhaustive Pattern Matching**
```gleam
// Compiler ensures all cases are handled
pub fn handle_status_change(status: SessionStatus) -> String {
  case status {
    Active -> "Session is now active"
    Paused -> "Session has been paused"  
    Completed -> "Session completed successfully"
    // Archived -> "Session archived"  // Compiler error if this is missing
  }
}
```

#### 3. **Immutable State Transformations**
```gleam
// State changes are pure functions - no side effects
pub fn process_session_update(session: SessionState, update: Update) -> SessionState {
  case update {
    AddParticipant(user) -> add_participant(session, user.id, user.name, user.role)
    UpdateContent(content) -> update_content(session, content)
    ChangeStatus(status) -> SessionState(..session, status: status)
  }
}
```

#### 4. **Self-Documenting APIs**
```gleam
// Function signatures serve as documentation
pub fn create_collaborative_session(
  title: String,
  max_participants: Int,
  moderator: User,
  settings: SessionSettings,
) -> Result(SessionState, CreateSessionError)
```

### Development Workflow with Gleam

#### 1. **Building Gleam Code**
```bash
# Build Gleam modules
cd gleam_state && gleam build

# The compiled code is automatically available in Elixir
# due to the mix.exs configuration
```

#### 2. **Testing Gleam Code**
```bash
# Run Gleam tests
cd gleam_state && gleam test

# Test from Elixir side
mix test test/my_app/gleam/
```

#### 3. **IDE Support**
- **VS Code**: Install the Gleam extension for syntax highlighting and type checking
- **Neovim/Vim**: Use the gleam.vim plugin
- **Emacs**: Use gleam-mode

### Performance Considerations

✅ **Gleam Strengths:**
- Compiles to highly optimized Erlang bytecode
- Zero-cost abstractions for type safety
- Efficient pattern matching
- Tail call optimization

⚠️ **Trade-offs:**
- Additional compilation step
- Learning curve for functional programming
- Smaller ecosystem compared to Elixir
- JSON serialization overhead for Elixir interop

### When to Expand Gleam Usage

Start small and expand based on success:

1. **Phase 1**: Use for critical state models (sessions, users)
2. **Phase 2**: Add complex business logic and validation
3. **Phase 3**: Consider for data transformation pipelines
4. **Phase 4**: Evaluate for performance-critical computations

The Gleam integration provides an excellent balance of type safety and functional programming benefits while maintaining full compatibility with your Elixir/Phoenix application.

## 🎨 Customizing for Your Domain

This guide uses generic examples (`MyApp`, `content_generation`, `Session`), but you should adapt them to your specific domain:

### Quick Customization Checklist
- [ ] Replace `MyApp` with your actual application name (e.g., `ChatApp`, `TodoManager`, `DocumentEditor`)
- [ ] Replace `content_generation` with your specific job types (e.g., `document_processing`, `image_analysis`, `data_sync`)
- [ ] Update domain models (`Session`, `Content`) to match your entities (`Document`, `Message`, `Project`)
- [ ] Modify LLM prompts and schemas to fit your use case
- [ ] Adapt the frontend theme and components to your application's purpose
- [ ] Update queue names, database schemas, and API endpoints accordingly
- [ ] Customize the observability dashboards for your specific metrics

### Domain Examples
- **Document Collaboration**: `DocumentApp.Jobs.DocumentProcessing`, `DocumentApp.Data.Document`
- **Chat Application**: `ChatApp.Jobs.MessageAnalysis`, `ChatApp.Data.Conversation`
- **Project Management**: `ProjectApp.Jobs.TaskGeneration`, `ProjectApp.Data.Project`
- **Content Platform**: `ContentApp.Jobs.ContentModeration`, `ContentApp.Data.Article`

The architectural patterns, observability setup, and real-time features remain the same regardless of your domain - only the naming and specific business logic will change.
