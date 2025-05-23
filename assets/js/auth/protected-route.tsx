import React from "react";
import { Box, Spinner, Center, Button, VStack, Text } from "@chakra-ui/react";
import { useAuth } from "./use-auth";

export const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading, login } = useAuth();

  // During initial loading
  if (isLoading) {
    return (
      <Center h="100vh" bg="area51.900">
        <Spinner color="terminal.500" size="xl" thickness="4px" />
      </Center>
    );
  }

  if (!isAuthenticated) {
    return (
      <Center h="100vh" bg="area51.900">
        <VStack
          spacing={6}
          bg="rgba(0, 10, 5, 0.8)"
          p={6}
          borderWidth="2px"
          borderColor="terminal.600"
          borderRadius="md"
          boxShadow="0 0 20px rgba(0, 230, 58, 0.25)"
          backdropFilter="blur(10px)"
          _hover={{
            boxShadow: "0 0 25px rgba(0, 230, 58, 0.35)",
          }}
        >
          <Text
            color="#1aff56"
            fontSize="2xl"
            fontFamily="heading"
            textTransform="uppercase"
            textShadow="0 0 5px rgba(0, 230, 58, 0.4)"
            letterSpacing="1px"
          >
            AREA 51 CLEARANCE REQUIRED
          </Text>
          <Box p={4} maxW="md" textAlign="center">
            <Text color="#49ff78" fontFamily="mono" mb={6}>
              You need to authenticate to access Area 51 classified files.
            </Text>
            <VStack spacing={4}>
              <Button
                bg="#00e63a"
                color="black"
                border="2px solid"
                borderColor="#00b32e"
                onClick={login}
                _hover={{
                  transform: "translateY(-2px)",
                  boxShadow: "0 0 15px #00ff44",
                  bg: "#1aff56",
                }}
              >
                [ AUTHENTICATE ]
              </Button>
            </VStack>
          </Box>
        </VStack>
      </Center>
    );
  }

  return <>{children}</>;
};
