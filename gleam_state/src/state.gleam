import gleam/json
import gleam/list
import gleam/string

pub type Clue {
  Clue(title: String, description: String)
}

pub fn encode_clue(clue: Clue) -> json.Json {
  json.object([
    #("title", json.string(clue.title)),
    #("description", json.string(clue.description)),
  ])
}

pub type InvestigationCard {
  InvestigationCard(id: Int, title: String)
}

pub type State {
  InvestigationState(id: Int, clues: List(Clue), goal: String, title: String)
  Navigation(investigations: List(InvestigationCard))
  Empty
}

pub fn new_state() {
  Empty
}

pub fn new_investigation_card(id: Int, title: String) {
  InvestigationCard(id, title)
}

pub fn set_state_to_investigation(
  _state: State,
  id: Int,
  clues: List(Clue),
  goal: String,
  title: String,
) {
  InvestigationState(
    id,
    clues
      |> list.map(fn(clue) {
        Clue(..clue, title: clue.title |> string.uppercase)
      }),
    goal,
    title,
  )
}
