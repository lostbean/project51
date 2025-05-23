import LiveState from "phx-live-state";
import { useState, useEffect } from "react";

export const useLiveState = (liveState: LiveState, initialState: any) => {
  const [state, setState] = useState(initialState);
  useEffect(() => {
    liveState.connect();
    const handleStateChange = ({ detail: { state } }) => setState(state);
    liveState.addEventListener("livestate-change", handleStateChange);
    return () => {
      liveState.removeEventListener("livestate-change", handleStateChange);
    };
  }, [liveState]);

  const pushEvent = (event, payload) => {
    return new Promise((resolve) => {
      const handleReply = ({ detail: { response } }) => {
        liveState.removeEventListener("livestate-reply", handleReply);
        resolve(response);
      };
      liveState.addEventListener("livestate-reply", handleReply);
      liveState.pushEvent(event, payload);
    });
  };

  return [state, pushEvent];
};
