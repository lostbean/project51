import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import Game from "./components/game";
import SessionList from "./components/session_list";
import { ChakraProvider, extendTheme } from "@chakra-ui/react";

import LiveState from "phx-live-state";

// Create a custom theme with Area 51 inspired colors
const theme = extendTheme({
  colors: {
    brand: {
      50: "#e3f2fd",
      100: "#bbdefb",
      200: "#90caf9",
      300: "#64b5f6",
      400: "#42a5f5",
      500: "#2196f3", // Primary blue
      600: "#1e88e5",
      700: "#1976d2",
      800: "#1565c0",
      900: "#0d47a1",
    },
    alien: {
      50: "#e8f5e9",
      100: "#c8e6c9",
      200: "#a5d6a7",
      300: "#81c784",
      400: "#66bb6a",
      500: "#4caf50", // Alien green
      600: "#43a047",
      700: "#388e3c",
      800: "#2e7d32",
      900: "#1b5e20",
    },
    area51: {
      50: "#eceff1",
      100: "#cfd8dc",
      200: "#b0bec5",
      300: "#90a4ae",
      400: "#78909c",
      500: "#607d8b", // Military gray
      600: "#546e7a",
      700: "#455a64",
      800: "#37474f",
      900: "#263238",
    },
  },
  fonts: {
    heading: "system-ui, sans-serif",
    body: "system-ui, sans-serif",
  },
  styles: {
    global: {
      body: {
        bg: "#1a202c",
        color: "white",
      },
    },
  },
});

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
root.render(
  <ChakraProvider theme={theme}>
    <App />
  </ChakraProvider>
);
