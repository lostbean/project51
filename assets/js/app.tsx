import React, { useState, useEffect } from "react";
import { createRoot } from "react-dom/client";
import Game from "./components/game";
import SessionList from "./components/session_list";
import JobQueueSidebar from "./components/job-queue-sidebar";
import MysteryGenerationButton from "./components/mystery-generation-button";
import { ChakraProvider, extendTheme, Center, Spinner, Box } from "@chakra-ui/react";
import { Auth0Provider51 } from "./auth/auth-provider";
import { useAuth } from "./auth/use-auth";
import { ProtectedRoute } from "./auth/protected-route";
import { useJobQueue } from "./hooks/use-job-queue";

import LiveState from "phx-live-state";

// Create a custom theme with retro computer terminal aesthetics
const theme = extendTheme({
  colors: {
    brand: {
      50: "#d4ffde",
      100: "#a6ffbc",
      200: "#77ff9a",
      300: "#49ff78",
      400: "#1aff56",
      500: "#00e63a", // Terminal green
      600: "#00b32e",
      700: "#008022",
      800: "#004d15",
      900: "#001a05",
    },
    alien: {
      50: "#d4ffde",
      100: "#a6ffbc",
      200: "#77ff9a",
      300: "#49ff78",
      400: "#1aff56",
      500: "#00e63a",
      600: "#00b32e",
      700: "#008022",
      800: "#004d15",
      900: "#001a05",
    },
    terminal: {
      50: "#d4ffde",
      101: "#a6ffbc",
      200: "#77ff9a",
      300: "#49ff78",
      400: "#1aff56",
      500: "#00e63a", // Terminal green
      600: "#00b32e",
      700: "#008022",
      800: "#004d15",
      900: "#001a05",
    },
    area51: {
      50: "#eceff1",
      100: "#cfd8dc",
      200: "#b0bec5",
      300: "#90a4ae",
      400: "#78909c",
      500: "#607d8b",
      600: "#546e7a",
      700: "#455a64",
      800: "#101418", // Dark terminal background
      900: "#000a02", // Even darker terminal background
    },
  },
  fonts: {
    heading: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
    body: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
    mono: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
  },
  shadows: {
    outline: "0 0 0 2px #00e63a",
    terminal: "0 0 12px #00e63a60",
    glow: "0 0 15px #00ff44",
  },
  styles: {
    global: {
      body: {
        bg: "#000a02", // Very dark green/black
        color: "#00e63a", // Terminal green
        fontFamily: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
        lineHeight: "1.2",
        letterSpacing: "0.5px",
      },
      "::selection": {
        backgroundColor: "terminal.700",
        color: "white",
      },
      "h1, h2, h3, h4, h5, h6": {
        letterSpacing: "1px",
        textShadow: "0 0 5px #00e63a60",
      },
    },
  },
  components: {
    Button: {
      baseStyle: {
        fontFamily: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
        fontWeight: "normal",
        letterSpacing: "1px",
        textTransform: "uppercase",
        transition: "all 0.2s ease-in-out",
      },
      variants: {
        solid: {
          bg: "terminal.600",
          color: "black",
          border: "2px solid",
          borderColor: "terminal.400",
          _hover: {
            bg: "terminal.500",
            boxShadow: "0 0 15px #00ff44",
            textShadow: "0 0 5px #00e63a",
          },
          _active: {
            bg: "terminal.700",
            transform: "translateY(2px)",
          },
          _focus: {
            boxShadow: "0 0 0 2px #00e63a, 0 0 15px #00ff44",
          },
        },
        outline: {
          border: "2px solid",
          borderColor: "terminal.600",
          color: "terminal.400",
          _hover: {
            bg: "transparent",
            color: "terminal.300",
            boxShadow: "0 0 10px #00ff44",
            textDecoration: "none",
          },
          _focus: {
            boxShadow: "0 0 0 2px #00e63a, 0 0 10px #00ff44",
          },
        },
        ghost: {
          color: "terminal.500",
          _hover: {
            bg: "rgba(0, 230, 58, 0.08)",
            color: "terminal.300",
            textShadow: "0 0 5px #00e63a",
          },
        },
      },
    },
    Input: {
      baseStyle: {
        field: {
          fontFamily: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
          borderColor: "terminal.600",
          caretColor: "terminal.400",
          _placeholder: {
            color: "terminal.700",
          },
        },
      },
      variants: {
        filled: {
          field: {
            bg: "area51.900",
            borderWidth: "1px",
            borderStyle: "solid",
            borderColor: "terminal.700",
            _hover: {
              bg: "area51.800",
              borderColor: "terminal.600",
            },
            _focus: {
              bg: "area51.800",
              borderColor: "terminal.500",
              boxShadow: "0 0 0 1px #00e63a, 0 0 10px #00ff4430",
            },
          },
        },
      },
      defaultProps: {
        variant: "filled",
      },
    },
    Textarea: {
      baseStyle: {
        fontFamily: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
        borderColor: "terminal.600",
        _placeholder: {
          color: "terminal.700",
        },
      },
      variants: {
        filled: {
          bg: "area51.900",
          borderWidth: "1px",
          borderStyle: "solid",
          borderColor: "terminal.700",
          _hover: {
            bg: "area51.800",
            borderColor: "terminal.600",
          },
          _focus: {
            bg: "area51.800",
            borderColor: "terminal.500",
            boxShadow: "0 0 0 1px #00e63a, 0 0 10px #00ff4430",
          },
        },
      },
      defaultProps: {
        variant: "filled",
      },
    },
    Card: {
      baseStyle: {
        container: {
          border: "1px solid",
          borderColor: "terminal.700",
          boxShadow: "0 2px 5px rgba(0, 0, 0, 0.2)",
          transition: "transform 0.2s, box-shadow 0.2s",
          _hover: {
            boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
          },
        },
        header: {
          fontFamily: "'VT323', 'Share Tech Mono', 'Courier New', monospace",
          letterSpacing: "1px",
        },
        body: {
          fontFamily: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
        },
      },
    },
    Heading: {
      baseStyle: {
        letterSpacing: "1px",
        textShadow: "0 0 5px rgba(0, 230, 58, 0.4)",
      },
    },
    Badge: {
      baseStyle: {
        fontFamily: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
        letterSpacing: "0.5px",
      },
    },
    Drawer: {
      baseStyle: {
        dialog: {
          bg: "area51.800",
          borderLeft: "1px solid",
          borderColor: "terminal.700",
        },
      },
    },
    Tooltip: {
      baseStyle: {
        bg: "area51.800",
        color: "terminal.400",
        borderColor: "terminal.700",
        borderWidth: "1px",
        fontFamily: "'Share Tech Mono', 'VT323', 'Courier New', monospace",
        letterSpacing: "0.5px",
        boxShadow: "0 0 5px rgba(0, 230, 58, 0.3)",
      },
    },
  },
});

// Session List Container that handles LiveState creation
const SessionListContainer = ({
  createLiveState,
  onSessionSelect,
  recentSessions,
}) => {
  const [liveState, setLiveState] = useState(null);

  useEffect(() => {
    async function createChannel() {
      const channel = await createLiveState("session_list");
      await setLiveState(channel);
    }
    createChannel();
  }, []);

  if (liveState) {
    return (
      <SessionList
        socket={liveState}
        onSessionSelect={onSessionSelect}
        recentSessions={recentSessions}
      />
    );
  }
  return <></>;
};

// Game Container that handles LiveState creation
const GameContainer = ({ createLiveState, sessionId, onBackToList }) => {
  const [liveState, setLiveState] = useState(null);

  useEffect(() => {
    async function createChannel() {
      const channel = await createLiveState(`investigation:${sessionId}`);
      await setLiveState(channel);
    }
    createChannel();
  }, []);

  if (liveState) {
    return (
      <Game
        socket={liveState}
        sessionId={sessionId}
        onBackToList={onBackToList}
      />
    );
  }
  return <></>;
};

const App = () => {
  const [currentSessionId, setCurrentSessionId] = useState<number | null>(null);
  const [recentSessions, setRecentSessions] = useState<number[]>(() => {
    // Load recent sessions from localStorage if available
    const storedSessions = localStorage.getItem("recentSessions");
    return storedSessions ? JSON.parse(storedSessions) : [];
  });
  const { user, isAuthenticated, getToken } = useAuth();
  
  // Job queue management
  const {
    jobs,
    isConnected: jobQueueConnected,
    cancelJob,
    refreshJobs,
    error: jobQueueError
  } = useJobQueue({ 
    userId: user?.sub || '', 
    socketUrl: "ws://localhost:4000/socket" 
  });

  // Function to create a LiveState connection with user data
  const createLiveState = async (topic: string) => {
    let params = {};

    // Only add the user data if the user is authenticated
    if (isAuthenticated && user) {
      const token = await getToken();

      if (token) {
        params = { token };
      }
    }

    return new LiveState({
      topic,
      url: "ws://localhost:4000/socket",
      params,
    });
  };

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

  // Main content based on current state
  const renderMainContent = () => {
    if (currentSessionId === null) {
      return (
        <SessionListContainer
          createLiveState={createLiveState}
          onSessionSelect={handleSessionSelect}
          recentSessions={recentSessions}
        />
      );
    } else {
      return (
        <GameContainer
          createLiveState={createLiveState}
          sessionId={currentSessionId}
          onBackToList={handleBackToList}
        />
      );
    }
  };

  return (
    <Box position="relative">
      {/* Main content with margin to account for sidebar */}
      <Box mr="350px">
        {renderMainContent()}
      </Box>
      
      {/* Job Queue Sidebar */}
      {isAuthenticated && user && (
        <JobQueueSidebar
          jobs={jobs}
          onJobCancel={cancelJob}
          onJobRefresh={refreshJobs}
          isConnected={jobQueueConnected}
        />
      )}
    </Box>
  );
};

const rootElement = document.getElementById("root");
const root = createRoot(rootElement!);
root.render(
  <Auth0Provider51>
    <ProtectedRoute>
      <ChakraProvider theme={theme}>
        <App />
      </ChakraProvider>
    </ProtectedRoute>
  </Auth0Provider51>,
);
