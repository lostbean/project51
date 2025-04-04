import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import Game from "./components/game";
import SessionList from "./components/session_list";

import LiveState from "phx-live-state";

const App = () => {
  const [currentSessionId, setCurrentSessionId] = useState<number | null>(null);
  const [recentSessions, setRecentSessions] = useState<number[]>(() => {
    // Load recent sessions from localStorage if available
    const storedSessions = localStorage.getItem("recentSessions");
    return storedSessions ? JSON.parse(storedSessions) : [];
  });

  // When a session is selected, create a new LiveState connection and switch to game mode
  const handleSessionSelect = (sessionId: number | null) => {
    if (sessionId !== null) {
      // Update recent sessions list (move to top if exists, add if new)
      const updatedSessions = [
        sessionId,
        ...recentSessions.filter((id) => id !== sessionId),
      ].slice(0, 10); // Keep only the 10 most recent

      setRecentSessions(updatedSessions);
      localStorage.setItem("recentSessions", JSON.stringify(updatedSessions));
    }

    setCurrentSessionId(sessionId);
  };

  // Handle going back to the session list
  const handleBackToList = () => {
    setCurrentSessionId(null);
  };

  // If no session is selected, show the session list
  if (currentSessionId === null) {
    const liveState = new LiveState({
      topic: "session_list",
      url: "ws://localhost:4000/socket",
    });
    return (
      <SessionList
        socket={liveState}
        onSessionSelect={handleSessionSelect}
        recentSessions={recentSessions}
      />
    );
  } else {
    // Otherwise show the game with the selected session
    const liveState = new LiveState({
      topic: `investigation:${currentSessionId}`,
      url: "ws://localhost:4000/socket",
    });

    return (
      <Game
        socket={liveState}
        sessionId={currentSessionId}
        onBackToList={handleBackToList}
      />
    );
  }
};

const rootElement = document.getElementById("root");
const root = createRoot(rootElement!);
root.render(<App />);
