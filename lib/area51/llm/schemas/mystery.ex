defmodule Area51LLM.Schemas.Mystery do
  use Ecto.Schema
  use Instructor

  @moduledoc """
  Schema and type definition for a mystery structure used with Instructor to get structured output from an LLM.
  """

  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          solution: String.t(),
          narrative: String.t()
        }

  embedded_schema do
    field :title, :string
    field :description, :string
    field :solution, :string
    field :narrative, :string
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required([:title, :description, :solution, :narrative])
  end

  def changeset(mystery, attrs) do
    mystery
    |> Ecto.Changeset.cast(attrs, [:title, :description, :solution, :narrative])
    |> Ecto.Changeset.validate_required([:title, :description, :solution, :narrative])
  end
end
