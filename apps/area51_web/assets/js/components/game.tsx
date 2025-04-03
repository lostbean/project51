import LiveState from "phx-live-state";
import React, { useState, useEffect } from "react";

const useLiveState = (liveState: LiveState, initialState: any) => {
  const [state, setState] = useState(initialState);
  useEffect(() => {
    liveState.connect();
    const handleStateChange = ({ detail: { state } }) => setState(state);
    liveState.addEventListener("livestate-change", handleStateChange);
    return () => {
      liveState.removeEventListener("livestate-change", handleStateChange);
    };
  });

  const pushEvent = (event, payload) => {
    liveState.pushEvent(event, payload);
  };

  return [state, pushEvent];
};

const Game = ({ socket, sessionId }) => {
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

  return (
    <div>
      <h1>Area 51 Investigation: Session {sessionId}</h1>
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
    </div>
  );
};

export default Game;
