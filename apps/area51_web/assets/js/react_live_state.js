import { useState, useEffect } from "react";

/**
 * Custom hook to use LiveState with React
 * 
 * @param {LiveState} liveState - The LiveState instance to connect to
 * @param {Object} initialState - The initial state to use
 * @returns {Array} - [state, pushEvent] where state is the current state and pushEvent is a function to call events
 */
export const useLiveState = (liveState, initialState) => {
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