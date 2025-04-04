defmodule Area51Data.GameSession do
  use Ecto.Schema
  import Ecto.Changeset
  # Using Repo directly for operations

  alias Area51Data.Repo

  schema "game_sessions" do
    field :narrative, :string, default: ""
    field :title, :string
    field :description, :string
    field :solution, :string
    has_many :clues, Area51Data.Clue
    has_many :player_contributions, Area51Data.PlayerContribution

    timestamps()
  end

  @doc false
  def changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:narrative, :title, :description, :solution])
    |> validate_required([:narrative])
  end

  def fetch_or_create_new_game_session(id, narrative_params) when is_map(narrative_params) do
    case Repo.get_by(Area51Data.GameSession, id: id) do
      nil ->
        # Create a new session with the provided narrative parameters
        Repo.insert!(%Area51Data.GameSession{
          narrative: narrative_params.starting_narrative,
          title: narrative_params.title,
          description: narrative_params.description,
          solution: narrative_params.solution
        })

      existing_session ->
        existing_session
    end
  end

  def fetch_or_create_new_game_session(id, new_narrative) when is_binary(new_narrative) do
    Repo.get_by(Area51Data.GameSession, id: id) ||
      Repo.insert!(%Area51Data.GameSession{narrative: new_narrative})
  end

  def update_narrative(id, narrative) do
    game_session = Repo.get_by!(Area51Data.GameSession, id: id)

    game_session
    |> cast(%{narrative: narrative}, [:narrative])
    |> Repo.update!()
  end

  @doc """
  Get a list of all game sessions
  """
  def list_game_sessions do
    Repo.all(Area51Data.GameSession)
  end

  @doc """
  Get a formatted list of game sessions for UI display
  """
  def list_sessions_for_ui do
    Repo.all(Area51Data.GameSession)
    |> Enum.map(fn session ->
      %{
        id: session.id,
        title: session.title || "Untitled Investigation",
        description: session.description || "No description available",
        created_at: session.inserted_at
      }
    end)
  end

  @doc """
  Get a specific game session by ID
  """
  def get_game_session(id) do
    Repo.get(Area51Data.GameSession, id)
  end

  @doc """
  Create a new game session with mystery data
  """
  def create_game_session(mystery_data) do
    %Area51Data.GameSession{}
    |> cast(
      %{
        narrative: mystery_data.starting_narrative,
        title: mystery_data.title,
        description: mystery_data.description,
        solution: mystery_data.solution
      },
      [:narrative, :title, :description, :solution]
    )
    |> Repo.insert!()
  end

  def data_to_core(%Area51Data.GameSession{} = game_session) do
    %Area51Core.GameSession{
      narrative: game_session.narrative,
      id: game_session.id,
      title: game_session.title,
      description: game_session.description
    }
  end
end
