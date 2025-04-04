import React, { useState } from "react";
import { useLiveState } from "../react_live_state";

const Game = ({ socket, sessionId, onBackToList }) => {
  const [input, setInput] = useState("");
  const [state, pushEvent] = useLiveState(socket, {});

  const onButtonClick = (event) => {
    event.preventDefault();
    if (input) {
      pushEvent("new_input", { input: input });
      setInput("");
    }
  };

  let narrative = "...";
  if (state.game_session) {
    narrative = state.game_session.narrative;
  }

  let title = "Area 51 Investigation";
  let description = "";
  if (state.game_session) {
    if (state.game_session.title) {
      title = state.game_session.title;
    }
    if (state.game_session.description) {
      description = state.game_session.description;
    }
  }

  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <h1>{title}</h1>
        <button onClick={onBackToList} style={{ padding: "8px 12px" }}>
          Back to Sessions
        </button>
      </div>
      {description && (
        <p>
          <em>{description}</em>
        </p>
      )}
      <div
        style={{
          border: "1px solid #ccc",
          padding: "10px",
          marginBottom: "10px",
          whiteSpace: "pre-line",
        }}
      >
        {narrative}
      </div>
      <input
        type="text"
        value={input}
        onChange={(ev) => setInput(ev.target.value)}
        placeholder="Enter your observation or action..."
        style={{ width: "100%", padding: "8px", boxSizing: "border-box" }}
      />
      <button onClick={onButtonClick}>Submit</button>

      {state.clues && state.clues.length > 0 && (
        <div className="clues-panel">
          <h3>Discovered Clues</h3>
          <ul>
            {state.clues.map((clue, index) => (
              <li key={index}>{clue.content}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default Game;
