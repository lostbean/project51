# 👽 Area 51: Unveiling the Unknown 🕵️‍♀️

Welcome to **Area 51: Unveiling the Unknown**, a real-time collaborative investigation game powered by Elixir, Phoenix, React, and Large Language Models (LLMs)! 🚀 Dive into the mysteries of Area 51, work with fellow investigators, and unravel the secrets hidden within this enigmatic location.

## 🎮 The Game

In **Area 51: Unveiling the Unknown**, you and your team of investigators are tasked with uncovering the truth behind the legendary Area 51. 🕵️‍♂️ Collaborate in real-time, share your findings, and let the LLM-powered game master guide your investigation.

### How to Play

1.  **Join an Investigation:** Start a new investigation or join an existing one.
2.  **Collaborate:** Share your observations, theories, and actions with your team.
3.  **Interact with the LLM:** The game master, powered by an LLM, will dynamically respond to your inputs, evolving the narrative in real-time.
4.  **Uncover Clues:** Discover hidden clues and piece together the puzzle.
5.  **Solve the Mystery:** Work together to uncover the truth behind Area 51!

## 🛠️ Tech Stack

-   **Elixir & Phoenix:** Robust and scalable backend for real-time communication and application logic. ⚡
-   **React:** Dynamic and responsive frontend for an engaging user experience. ⚛️
-   **Phoenix Channels:** Real-time communication via WebSockets. 📡
-   **LiveState:** Efficient state synchronization between the backend and frontend. 🔄
-   **Ecto & SQLite:** Data persistence for game sessions, clues, and logs. 💾
-   **Reactor Workflows:** Composable, type-safe workflow orchestration for AI and conventional processes. 🔄
-   **Oban Job Management:** Reliable background job processing with telemetry and monitoring. ⚙️
-   **Gleam:** Type-safe functional programming for state modeling. 🌟

## 🧮 Architecture & Design
See the [deep search analysis](./Architecture_Deep_Search.md) for detailed exploration.

### Key Architectural Changes

-   **From Magus to Reactor:** All workflows now use [Reactor](https://hexdocs.pm/reactor/) for composable, type-safe process orchestration
-   **Oban Integration:** Background job processing with comprehensive telemetry and real-time status updates
-   **Reactor Observability:** Custom middleware providing OpenTelemetry tracing, structured logging, and telemetry events
-   **PubSub-Driven UI:** Real-time updates flow from backend processes through PubSub to LiveState channels

## System Architecture Overview

```mermaid
graph TB
    subgraph "Area 51 Application"
        subgraph "area51_web"
            web_app[Phoenix Web App]--hosts-->assets[React Frontend]
            web_app--uses-->channels[Phoenix Channels]
            web_app--validates-->auth[Guardian Auth]
            channels--connects-->live_state[LiveState]
        end

        subgraph "area51_core"
            domain[Domain Models]--defines-->game_state[Game State]
            domain--defines-->game_session[Game Session]
            domain--defines-->clue[Clue]
            domain--defines-->user[User]
        end

        subgraph "area51_data"
            repo[Ecto Repo]--uses-->schemas[Database Schemas]
            schemas--maps to-->domain
            repo--persists-->game_sessions[Game Sessions]
            repo--persists-->investigation_logs[Investigation Logs]
            repo--persists-->clues[Clues]
            repo--persists-->player_contributions[Player Contributions]
        end

        subgraph "area51_llm"
            reactors[Reactor Workflows]--orchestrates-->investigation_reactor[Investigation Reactor]
            reactors--orchestrates-->mystery_reactor[Mystery Generation Reactor]
            investigation_reactor--generates-->narrative[Narrative]
            investigation_reactor--extracts-->new_clues[Clues]
            mystery_reactor--creates-->mystery_jobs[Mystery Jobs]
        end

        subgraph "area51_jobs"
            oban[Oban Job Processing]--executes-->mystery_worker[Mystery Generation Worker]
            oban--broadcasts-->pubsub[PubSub Events]
            mystery_worker--uses-->mystery_reactor
            pubsub--updates-->live_state
        end

        subgraph "area51_gleam"
            gleam_state[State Module]--provides-->type_safe_models[Type-Safe Models]
        end
    end

    external_llm[LLM Provider]--connects-->agent
    browser[Browser]--connects-->assets
    auth0[Auth0]--provides-->tokens[JWT Tokens]
    tokens--validated by-->auth

    area51_core--informs-->area51_gleam
    area51_core--accessed by-->area51_data
    area51_core--used by-->area51_web
    area51_web--uses-->area51_llm
    area51_jobs--processes-->background_tasks[Background Tasks]
    area51_jobs--publishes to-->pubsub
    live_state--synchronizes-->assets
    live_state--subscribes to-->pubsub
    live_state--uses-->domain
    reactors--integrates with-->oban
```

### Modularity and Separation of Concerns

The Area 51 project is structured as a single Elixir application, promoting clear separation of concerns through its modular design using namespaces under the main `Area51` module:

-   **Area51.Core:** Contains the domain models and core game logic.
-   **Area51.Data:** Handles data persistence using Ecto with job-specific schemas.
-   **Area51.Jobs:** Manages background job processing with Oban, including job-specific contexts and telemetry.
-   **Area51.Llm:** Encapsulates LLM integration using Reactor workflows for composable AI processes.
-   **Area51.Web:** Manages HTTP and WebSocket interfaces with real-time PubSub integration.
-   **Area51.Gleam:** Leverages Gleam for type-safe state modeling.
-   **Reactor.Middleware:** Provides observability middleware for workflow tracing and monitoring.

This modular approach using namespaces within a single application facilitates testing, allows components to evolve with clarity, and supports system scalability.

### State Management & Real-time Updates

The application implements a sophisticated state management strategy with comprehensive real-time capabilities:

-   **Backend State:** Game state is maintained in the Elixir backend, using Phoenix PubSub for real-time updates
-   **Frontend Synchronization:** LiveState library efficiently syncs backend state to the React frontend
-   **Event-Based Architecture:** State changes are driven by events, with the system responding to player actions and job completions
-   **Job-Driven Workflows:** Background jobs use Reactor workflows to orchestrate complex processes
-   **PubSub Integration:** Job status changes and completions automatically broadcast to LiveState channels
-   **Type-Safe State Modeling:** Gleam provides compile-time type safety for state definitions

State flows from the backend to the frontend through Phoenix Channels and LiveState, creating a consistent, real-time experience for all players in an investigation.

### Authentication & Authorization

Authentication and authorization are implemented using industry-standard patterns:

-   **IDP-Based Authentication:** Integration with Auth0 provides secure authentication services
-   **JWT-Based Authorization:** JSON Web Tokens handle authorization for protected resources
-   **ETS Caching:** Erlang Term Storage provides fast, lightweight caching of validation keys
-   **JWKS Integration:** Dynamic key fetching with ETS caching enables seamless key rotation support

The system validates JWTs using cached JWKS (JSON Web Key Sets), providing robust security with minimal performance overhead.

### Observability & Monitoring

Comprehensive observability is achieved through multi-layered instrumentation with specialized workflow monitoring:

-   **Telemetry:** Erlang/Elixir's telemetry library provides structured event emission
-   **OpenTelemetry:** Standardized tracing across service boundaries and Reactor workflows
-   **Reactor Middleware:** Custom observability middleware for workflow tracing, structured logging, and telemetry events
-   **Job Telemetry:** Oban job lifecycle events with job-specific telemetry handlers
-   **Structured Logging:** Consistent log formatting with contextual metadata and trace correlation
-   **Metrics Collection:** PromEx integration for Prometheus-compatible metrics
-   **Grafana Dashboards:** Pre-configured visualization for system performance and job monitoring

Traces follow requests through the system, from HTTP requests through channel operations, Reactor workflows, to job processing and LLM interactions, providing end-to-end visibility into system behavior.

### Language Interoperability

The project showcases seamless interoperation between multiple programming languages:

-   **Elixir:** Powers the core application logic and backend services
-   **Gleam:** Provides type-safe state modeling with compile-time guarantees
-   **TypeScript:** Ensures type safety in the React frontend
-   **JavaScript:** Supports the React component ecosystem

This polyglot approach leverages each language's strengths while maintaining clean integration points.

## 🚀 Setup

1.  **Prerequisites:**

    You can install all the dependencies using [Nix](https://nixos.org/download/). Use the following command to enter the development shell:
    ```bash
    nix develop
    ```

2.  **Install Elixir and NPM Dependencies:**
    ```bash
    mix setup
    ```

3.  **Configure Auth0 environment and OpenAI key:**

    Create a new Auth0 dev environment with SPA application type and callback `http://localhost:4000`. Make a copy of the `.env.example` file into `.env` and update the envars
    according the values defined into your Auth0 environment.

    Also include your OpenAI key in the `.env`, unless it's already part of your shell environment.

4.  **Start the observability system:**
    ```bash
    docker-compose -f docker-compose.observability.yml up -d
    ```

5.  **Start the Area51 application:**
    ```bash
    mix phx.server
    ```

6.  **Access the Game:**
    -   Open your web browser and navigate to `http://localhost:4000`.

## 📂 Project Structure

```
area51_investigation/
├── assets/                # Frontend assets (React, JavaScript, CSS)
├── config/                # Application configurations
├── lib/                   # Elixir application code
│   └── area51/
│       ├── core/          # Core game logic
│       ├── data/          # Data persistence
│       ├── gleam/         # Gleam integration
│       ├── llm/           # LLM integration
│       └── web/           # Phoenix web components (controllers, channels, etc.)
├── priv/                  # Private application data
│   ├── gettext/           # Localization files
│   ├── repo/              # Ecto migrations and seeds
│   └── static/            # Static assets (favicon, robots.txt, compiled JS/CSS in assets/)
├── test/                  # Test files
│   └── area51/
│       ├── core/
│       ├── data/
│       ├── gleam/
│       ├── llm/
│       └── web/
├── gleam_state/           # Gleam package for state modeling
├── mix.exs                # Project configuration
└── README.md              # Project documentation
```

**Note:** The Mermaid diagram above reflects the old umbrella structure and needs to be manually updated to represent the current single-application architecture with namespaced modules.

## 🧠 LLM Integration & Workflow Orchestration

The `Area51.Llm` module handles LLM integration using Reactor workflows for composable, type-safe AI processes. 🚀

-   **Reactor Workflows:** Composable workflow orchestration using [Reactor](https://hexdocs.pm/reactor/) for complex AI processes
-   **Instructor Integration:** Structured LLM outputs using [Instructor](https://hexdocs.pm/instructor/) with Ecto schemas
-   **Asynchronous Processing:** Background job processing with Oban for long-running AI operations
-   **Observability:** Full tracing and monitoring of AI workflows through custom Reactor middleware
-   **Job Management:** Mystery generation and other AI processes handled as background jobs with real-time status updates

### Key Components

-   **Investigation Reactor:** Orchestrates narrative generation and clue extraction workflows
-   **Mystery Generation Reactor:** Handles complex mystery creation processes as background jobs
-   **Reactor Middleware:** Provides OpenTelemetry tracing, structured logging, and telemetry events for all workflows

## Deployment

Build a release image with:
```bash
docker load < $(nix build .\#packages.aarch64-linux.image.area51.arm64 --no-link --print-out-paths)
docker run -e OPENAI_API_KEY=$OPENAI_API_KEY -p 4000:4000 -v area51db:/data area51:dirty
```

## 🤝 Contributing

We welcome contributions! Feel free to submit pull requests or open issues to improve the game. 🛠️

## 📜 License

This project is licensed under the [MIT License](LICENSE). 📄

---

Uncover the secrets of Area 51 and join the investigation! 🕵️‍♂️👽🚀
