import React from "react";
import { createRoot } from "react-dom/client";
import Game from "./components/game";

import LiveState from "phx-live-state";

export const liveState = new LiveState({
  topic: "investigation:0",
  url: "ws://localhost:4000/socket",
});

const App = () => {
  return <Game socket={liveState} sessionId={0} />;
};

const rootElement = document.getElementById("root");
const root = createRoot(rootElement!);
root.render(<App />);
