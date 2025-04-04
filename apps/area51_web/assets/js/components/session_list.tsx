import LiveState from "phx-live-state";
import React, { useState } from "react";
import { useLiveState } from "../react_live_state";

const SessionList = ({ socket, onSessionSelect, recentSessions = [] }) => {
  const [topic, setTopic] = useState("");
  const [state, pushEvent] = useLiveState(socket, { sessions: [] });

  const handleCreateSession = async () => {
    if (topic.trim() === "") {
      alert("Please enter a topic for the new session");
      return;
    }

    try {
      const response = await pushEvent("create_session", {
        topic: topic.trim(),
      });
      if (response.session_id) {
        onSessionSelect(response.session_id);
      } else if (response.error) {
        alert(`Error: ${response.error}`);
      }
    } catch (error) {
      console.error("Error creating session:", error);
      alert("Failed to create new session. Please try again.");
    }
  };

  const handleRefresh = () => {
    pushEvent("refresh_sessions", {});
  };

  return (
    <div className="session-list">
      <h1>Area 51 Investigations</h1>
      <p>Select an existing investigation or start a new one:</p>

      <div className="session-controls">
        <input
          type="text"
          value={topic}
          onChange={(e) => setTopic(e.target.value)}
          placeholder="Enter a topic for a new investigation..."
          style={{ width: "70%", padding: "8px", boxSizing: "border-box" }}
        />
        <button onClick={handleCreateSession}>Create New Investigation</button>
        <button onClick={handleRefresh}>Refresh List</button>
      </div>

      {recentSessions.length > 0 && (
        <div className="recent-sessions">
          <h2>Recently Visited Investigations</h2>
          <ul className="session-list">
            {recentSessions
              .map((sessionId) => {
                const sessionData = state.sessions?.find(
                  (s) => s.id === sessionId,
                );
                if (!sessionData) return null;

                return (
                  <li
                    key={sessionId}
                    className="session-item"
                    style={{ backgroundColor: "#f5f5f5" }}
                  >
                    <div className="session-info">
                      <h3>{sessionData.title}</h3>
                      <p>{sessionData.description}</p>
                      <p>
                        <small>
                          Created:{" "}
                          {new Date(sessionData.created_at).toLocaleString()}
                        </small>
                      </p>
                    </div>
                    <button
                      onClick={() => onSessionSelect(sessionId)}
                      style={{ backgroundColor: "#4c9aff" }}
                    >
                      Resume Investigation
                    </button>
                  </li>
                );
              })
              .filter(Boolean)}
          </ul>
        </div>
      )}

      <div className="existing-sessions">
        <h2>All Investigations</h2>
        {state.sessions && state.sessions.length > 0 ? (
          <ul className="session-list">
            {state.sessions
              // Filter out sessions that are already shown in the recent list
              .filter((session) => !recentSessions.includes(session.id))
              .map((session) => (
                <li key={session.id} className="session-item">
                  <div className="session-info">
                    <h3>{session.title}</h3>
                    <p>{session.description}</p>
                    <p>
                      <small>
                        Created: {new Date(session.created_at).toLocaleString()}
                      </small>
                    </p>
                  </div>
                  <button onClick={() => onSessionSelect(session.id)}>
                    Join Investigation
                  </button>
                </li>
              ))}
          </ul>
        ) : (
          <p>No active investigations found. Create a new one!</p>
        )}
      </div>
    </div>
  );
};

export default SessionList;
