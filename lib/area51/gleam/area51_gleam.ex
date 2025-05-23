defmodule Area51.Gleam do
  @moduledoc """
  Documentation for `Area51.Gleam`.
  """

  defmodule Clue do
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
    defmodule InvestigationState do
      @enforce_keys [:id, :clues, :goal, :title]
      defstruct id: nil, clues: [], goal: nil, title: nil

      @type t() :: %__MODULE__{
              id: integer(),
              clues: list(Area51.Gleam.Clue.t()),
              goal: String.t(),
              title: String.t()
            }
    end

    defmodule Navigation do
      @enforce_keys [:investigations]
      defstruct investigations: []

      @type t() :: %__MODULE__{
              investigations: list(Area51.Gleam.InvestigationCard.t())
            }
    end

    @type t() :: %InvestigationState{} | %Navigation{} | :empty

    def from_gleam({:investigation_state, id, clues, goal, title}) do
      %InvestigationState{
        id: id,
        clues: Enum.map(clues, &Area51.Gleam.Clue.from_gleam/1),
        goal: goal,
        title: title
      }
    end

    def from_gleam({:navigation, investigations}) do
      %Navigation{
        investigations: Enum.map(investigations, &Area51.Gleam.InvestigationCard.from_gleam/1)
      }
    end

    def from_gleam(:empty) do
      :empty
    end

    def to_gleam(%InvestigationState{id: id, clues: clues, goal: goal, title: title}) do
      {:investigation_state, id, Enum.map(clues, &Area51.Gleam.Clue.to_gleam/1), goal, title}
    end

    def to_gleam(%Navigation{investigations: investigations}) do
      {:navigation, Enum.map(investigations, &Area51.Gleam.InvestigationCard.to_gleam/1)}
    end

    def to_gleam(:empty) do
      :empty
    end
  end
end
