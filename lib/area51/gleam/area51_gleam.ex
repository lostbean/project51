defmodule Area51.Gleam do
  @moduledoc """
  Documentation for `Area51.Gleam`.
  """

  defmodule Clue do
    @moduledoc """
    Represents a clue discovered during an investigation,
    containing a title and a description.
    """
    @enforce_keys [:title, :description]
    defstruct title: nil, description: nil

    @type t() :: %__MODULE__{
            title: String.t(),
            description: String.t()
          }

    def from_gleam({:clue, title, description}) do
      %Clue{title: title, description: description}
    end

    def to_gleam(%Clue{title: title, description: description}) do
      {:clue, title, description}
    end

    defimpl Jason.Encoder, for: [__MODULE__] do
      def encode(%Clue{} = clue, opts) do
        Jason.Encode.map(
          Map.take(clue, [:title, :description]) |> Map.put(:_gleam_type_, :clue),
          opts
        )
      end
    end
  end

  defmodule InvestigationCard do
    @moduledoc """
    Represents a summarized card for an investigation, typically containing
    its ID and title. Used for displaying lists of investigations.
    """
    @enforce_keys [:id, :title]
    defstruct id: nil, title: nil

    @type t() :: %__MODULE__{
            id: integer(),
            title: String.t()
          }

    def from_gleam({:investigation_card, id, title}) do
      %InvestigationCard{id: id, title: title}
    end

    def to_gleam(%InvestigationCard{id: id, title: title}) do
      {:investigation_card, id, title}
    end
  end

  defmodule State do
    @moduledoc """
    Defines and handles different application states for interoperability with Gleam.

    This module encapsulates various state structures like `InvestigationState`
    (for active game investigations) and `Navigation` (for listing investigations),
    and provides functions to convert these states between Elixir and Gleam
    representations.
    """
    alias Area51.Gleam.Clue
    alias Area51.Gleam.InvestigationCard

    defmodule InvestigationState do
      @moduledoc """
      Defines the structure for the state of an active game investigation.
      It includes the investigation's ID, a list of discovered clues,
      the overall goal, and the title of the investigation.
      """
      @enforce_keys [:id, :clues, :goal, :title]
      defstruct id: nil, clues: [], goal: nil, title: nil

      @type t() :: %__MODULE__{
              id: integer(),
              clues: list(Clue.t()),
              goal: String.t(),
              title: String.t()
            }
    end

    defmodule Navigation do
      @moduledoc """
      Represents the navigation state, primarily holding a list of
      `Area51.Gleam.InvestigationCard` structs for display.
      """
      @enforce_keys [:investigations]
      defstruct investigations: []

      @type t() :: %__MODULE__{
              investigations: list(InvestigationCard.t())
            }
    end

    @type t() :: %InvestigationState{} | %Navigation{} | :empty

    def from_gleam({:investigation_state, id, clues, goal, title}) do
      %InvestigationState{
        id: id,
        clues: Enum.map(clues, &Clue.from_gleam/1),
        goal: goal,
        title: title
      }
    end

    def from_gleam({:navigation, investigations}) do
      %Navigation{
        investigations: Enum.map(investigations, &InvestigationCard.from_gleam/1)
      }
    end

    def from_gleam(:empty) do
      :empty
    end

    def to_gleam(%InvestigationState{id: id, clues: clues, goal: goal, title: title}) do
      {:investigation_state, id, Enum.map(clues, &Clue.to_gleam/1), goal, title}
    end

    def to_gleam(%Navigation{investigations: investigations}) do
      {:navigation, Enum.map(investigations, &InvestigationCard.to_gleam/1)}
    end

    def to_gleam(:empty) do
      :empty
    end
  end
end
