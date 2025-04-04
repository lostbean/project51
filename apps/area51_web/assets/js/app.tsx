import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import Game from "./components/game";
import SessionList from "./components/session_list";

import LiveState from "phx-live-state";

const App = () => {
  const [currentSessionId, setCurrentSessionId] = useState<number | null>(null);

  // When a session is selected, create a new LiveState connection and switch to game mode
  const handleSessionSelect = (sessionId: number | null) => {
    setCurrentSessionId(sessionId);
  };

  // If no session is selected, show the session list
  if (currentSessionId === null) {
    const liveState = new LiveState({
      topic: "session_list",
      url: "ws://localhost:4000/socket",
    });
    return (
      <SessionList socket={liveState} onSessionSelect={handleSessionSelect} />
    );
  } else {
    // Otherwise show the game with the selected session
    const liveState = new LiveState({
      topic: `investigation:${currentSessionId}`,
      url: "ws://localhost:4000/socket",
    });
    return <Game socket={liveState} sessionId={currentSessionId} />;
  }
};

const rootElement = document.getElementById("root");
const root = createRoot(rootElement!);
root.render(<App />);

