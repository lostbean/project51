# Area 51 Architecture Diagrams

This document provides visual representations of the current Area 51 architecture, focusing on the updated job management system, Reactor workflows, and real-time PubSub integration.

## State Management & Job Processing Flow

```mermaid
sequenceDiagram
    participant User
    participant ReactFrontend as React Frontend
    participant PhoenixChannels as Phoenix Channels
    participant LiveState
    participant GameState as Game State
    participant ReactorWorkflow as Reactor Workflow
    participant ObanJob as Oban Job
    participant PubSub as Phoenix PubSub
    participant LLMProvider as LLM Provider
    participant EctoRepo as Ecto Repo

    User->>ReactFrontend: Submit action/input
    ReactFrontend->>PhoenixChannels: Send event ("new_input")
    PhoenixChannels->>LiveState: Process event
    LiveState->>GameState: Update state
    LiveState->>ReactorWorkflow: Execute investigation workflow
    ReactorWorkflow->>LLMProvider: Send structured prompts
    LLMProvider->>ReactorWorkflow: Return validated responses
    ReactorWorkflow->>LiveState: Provide narrative & clues
    LiveState->>GameState: Update with workflow results
    LiveState->>EctoRepo: Persist state changes
    LiveState->>PubSub: Broadcast state changes
    PubSub->>PhoenixChannels: Notify all subscribers
    PhoenixChannels->>ReactFrontend: Push state changes
    ReactFrontend->>User: Update UI with new state
    
    Note over User, EctoRepo: Background Job Processing
    User->>ReactFrontend: Request mystery generation
    ReactFrontend->>PhoenixChannels: Send job request
    PhoenixChannels->>ObanJob: Enqueue mystery job
    ObanJob->>ReactorWorkflow: Execute mystery workflow
    ReactorWorkflow->>LLMProvider: Generate mystery content
    LLMProvider->>ReactorWorkflow: Return structured mystery
    ReactorWorkflow->>EctoRepo: Create game session
    ObanJob->>PubSub: Broadcast job completion
    PubSub->>PhoenixChannels: Notify job & session channels
    PhoenixChannels->>ReactFrontend: Update job status & session list
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant ReactFrontend as React Frontend
    participant Auth0
    participant PhoenixApp as Phoenix App
    participant GuardianAuth as Guardian Auth
    participant JWKSCache as JWKS Cache (ETS)

    User->>ReactFrontend: Access application
    ReactFrontend->>Auth0: Redirect to login
    Auth0->>User: Display login form
    User->>Auth0: Provide credentials
    Auth0->>ReactFrontend: Return with tokens
    ReactFrontend->>PhoenixApp: Request with JWT
    PhoenixApp->>GuardianAuth: Validate token
    GuardianAuth->>JWKSCache: Check for cached keys
    alt Keys not cached or expired
        JWKSCache->>Auth0: Fetch JWKS
        Auth0->>JWKSCache: Return JWKS
        JWKSCache->>GuardianAuth: Provide keys
    else Keys available
        JWKSCache->>GuardianAuth: Provide cached keys
    end
    GuardianAuth->>PhoenixApp: Validation result
    alt Valid token
        PhoenixApp->>ReactFrontend: Allow access
        ReactFrontend->>User: Display protected content
    else Invalid token
        PhoenixApp->>ReactFrontend: Deny access
        ReactFrontend->>User: Redirect to login
    end
```

## Reactor Workflow & Job Architecture

```mermaid
graph TD
    subgraph "Area51.Jobs - Job Management"
        JobContext[Job Context Modules]
        TelemetryHandler[Job Telemetry Handlers]
        ObanWorker[Oban Workers]
        
        JobContext--manages-->MysteryGenJob[Mystery Generation Job]
        TelemetryHandler--handles-->JobEvents[Job Lifecycle Events]
        ObanWorker--executes-->ReactorWorkflows
    end

    subgraph "Area51.Llm - Reactor Workflows"
        subgraph "Investigation Reactor"
            InvestigationReactor--step-->GenerateNarrative["Generate Narrative Step"]
            InvestigationReactor--step-->ExtractClues["Extract Clues Step"]
            InvestigationReactor--step-->ProcessOutcome["Process Outcome Step"]
            GenerateNarrative-->ExtractClues-->ProcessOutcome
        end

        subgraph "Mystery Generation Reactor"
            MysteryReactor--step-->GenerateDetails["Generate Mystery Details"]
            MysteryReactor--step-->CreateNarrative["Generate Narrative"]
            MysteryReactor--step-->ExtractInitialClues["Extract Initial Clues"]
            GenerateDetails-->CreateNarrative-->ExtractInitialClues
        end

        subgraph "Reactor.Middleware - Observability"
            OpenTelemetryMW[OpenTelemetry Middleware]
            StructuredLogging[Structured Logging Middleware]
            TelemetryEvents[Telemetry Events Middleware]
        end
    end

    subgraph "External Services"
        LLMProvider["LLM Provider API"]
        InstructorValidation["Instructor Schema Validation"]
    end

    InvestigationChannel--triggers-->InvestigationReactor
    JobManagementChannel--enqueues-->MysteryGenJob
    MysteryGenJob--executes-->MysteryReactor
    
    ReactorWorkflows--instrumented by-->OpenTelemetryMW
    ReactorWorkflows--logs via-->StructuredLogging
    ReactorWorkflows--emits-->TelemetryEvents
    
    ReactorWorkflows--calls-->LLMProvider
    LLMProvider--validates via-->InstructorValidation
    
    JobEvents--broadcasts to-->PubSub[Phoenix PubSub]
    PubSub--notifies-->LiveStateChannels[LiveState Channels]
```

## Component Interaction Model

```mermaid
graph LR
    subgraph "Frontend"
        RC["React Components"]--renders-->UI["User Interface"]
        LSH["useLiveState Hook"]--provides-->RC
        PCJ["Phoenix Channel JS"]--connects-->LSH
        JobHook["useJobManagement Hook"]--tracks-->JobStatus["Job Status"]
    end

    subgraph "Backend - Real-time Layer"
        PC["Phoenix Channels"]--handles-->Events["User Events"]
        LS["LiveState Channels"]--manages-->State["Server State"]
        JMC["Job Management Channel"]--tracks-->Jobs["Background Jobs"]
        SLC["Session List Channel"]--syncs-->Sessions["Game Sessions"]
        PC--routes to-->LS
        LS--subscribes to-->PubSub["Phoenix PubSub"]
        PubSub--broadcasts-->PC
    end

    subgraph "Backend - Processing Layer"
        ReactorWF["Reactor Workflows"]--orchestrates-->Steps["Workflow Steps"]
        ObanJobs["Oban Background Jobs"]--executes-->ReactorWF
        JobContexts["Job-Specific Contexts"]--manages-->ObanJobs
        TelemetryHandlers["Telemetry Handlers"]--monitors-->ObanJobs
    end

    subgraph "Backend - Data Layer"
        Core["Area51.Core Models"]--defines-->State
        DataSchemas["Area51.Data Schemas"]--maps-->Repo["Ecto Repo"]
        Repo--persists-->DB[("SQLite Database")]
    end

    PCJ--WebSocket-->PC
    User--interacts with-->UI
    UI--updates-->User
    
    LS--triggers-->ReactorWF
    JMC--enqueues-->ObanJobs
    ReactorWF--calls-->LLM["External LLM"]
    ReactorWF--updates-->Core
    ObanJobs--publishes to-->PubSub
    TelemetryHandlers--broadcasts-->PubSub
    Core--persists via-->DataSchemas
```
