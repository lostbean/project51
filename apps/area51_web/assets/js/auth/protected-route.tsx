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
        <VStack spacing={6}>
          <Text
            color="terminal.400"
            fontSize="2xl"
            fontFamily="heading"
            textTransform="uppercase"
          >
            AREA 51 CLEARANCE REQUIRED
          </Text>
          <Box
            p={4}
            bg="area51.800"
            borderWidth="1px"
            borderColor="terminal.700"
            maxW="md"
            textAlign="center"
          >
            <Text color="terminal.300" fontFamily="mono" mb={6}>
              You need to authenticate to access Area 51 classified files.
            </Text>
            <VStack spacing={4}>
              <Button
                colorScheme="brand"
                onClick={login}
                _hover={{
                  transform: "translateY(-2px)",
                  boxShadow: "0 0 15px #00ff44",
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
