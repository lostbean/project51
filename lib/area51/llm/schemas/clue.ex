defmodule Area51.LLM.Schemas.Clue do
  use Ecto.Schema

  @moduledoc """
  Schema and type definition for a single clue extracted from the narrative.
  """

  @derive {Jason.Encoder, only: [:content]}
  @type t :: %__MODULE__{
          content: String.t()
        }

  embedded_schema do
    field :content, :string
  end

  def changeset(clue, attrs) do
    clue
    |> Ecto.Changeset.cast(attrs, [:content])
    |> Ecto.Changeset.validate_required([:content])
  end
end

defmodule Area51.LLM.Schemas.ClueItem do
  use Ecto.Schema
  use Instructor

  @moduledoc """
  Schema for individual clue items used in Instructor responses.
  """

  @llm_doc """
  ## Field Descriptions:
  - content: the actual clue text content
  """

  @type t :: %__MODULE__{
          content: String.t()
        }

  @primary_key false
  embedded_schema do
    field(:content, :string)
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required([:content])
  end
end

defmodule Area51.LLM.Schemas.Clues do
  use Ecto.Schema
  use Instructor

  @moduledoc """
  Schema and type definition for a list of clues extracted from the narrative.
  """

  @llm_doc """
  ## Field Descriptions:
  - clues: array of clue objects containing content strings
  """

  @derive {Jason.Encoder, only: [:clues]}
  @type t :: %__MODULE__{
          clues: list(Area51.LLM.Schemas.ClueItem.t())
        }

  @primary_key false
  embedded_schema do
    embeds_many :clues, Area51.LLM.Schemas.ClueItem, on_replace: :delete
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required([:clues])
  end
end
