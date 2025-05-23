# Area51Gleam

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
This Gleam package is used as a local path dependency within the main Area51 Elixir project.
It is included in the main `mix.exs` as follows:

```elixir
def deps do
  [
    # The name :gleam_state is how the Elixir project refers to this path dependency.
    # The Gleam package defined within gleam_state/ (e.g., in its gleam.toml) might have a different name, such as 'area51_gleam'.
    {:gleam_state, path: "gleam_state/"}
  ]
end
```

As an internal component, its primary documentation and usage context are part of the main Area51 project.
For general information on Gleam and its standard libraries, please refer to the official Gleam documentation.
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/area51_gleam>.

