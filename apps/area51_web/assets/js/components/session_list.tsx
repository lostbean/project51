import React, { useState } from "react";
import { useLiveState } from "../react_live_state";
import {
  Box,
  Button,
  Container,
  Flex,
  Heading,
  Input,
  Text,
  SimpleGrid,
  VStack,
  Card,
  CardBody,
  CardFooter,
  Badge,
  Stack,
  HStack,
  Icon,
} from "@chakra-ui/react";

// Import components from their specific packages to avoid import issues
import { useToast } from "@chakra-ui/react";
import { Divider } from "@chakra-ui/react";
import { FiRefreshCw, FiPlusCircle, FiClock, FiUserPlus, FiFileText } from "react-icons/fi";

const SessionList = ({ socket, onSessionSelect, recentSessions = [] }) => {
  const [topic, setTopic] = useState("");
  const [state, pushEvent] = useLiveState(socket, { sessions: [] });
  const toast = useToast();
  
  // Add keyboard shortcut for creating new session with Enter key
  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey && topic.trim()) {
      e.preventDefault();
      handleCreateSession();
    }
  };

  const handleCreateSession = async () => {
    if (topic.trim() === "") {
      toast({
        title: "Topic Required",
        description: "Please enter a topic for the new investigation.",
        status: "warning",
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    try {
      const response = await pushEvent("create_session", {
        topic: topic.trim(),
      });
      if (response.session_id) {
        toast({
          title: "Investigation Created",
          description: "Your new investigation session has been created.",
          status: "success",
          duration: 3000,
          isClosable: true,
        });
        onSessionSelect(response.session_id);
      } else if (response.error) {
        toast({
          title: "Error",
          description: response.error,
          status: "error",
          duration: 3000,
          isClosable: true,
        });
      }
    } catch (error) {
      console.error("Error creating session:", error);
      toast({
        title: "Creation Failed",
        description: "Failed to create new investigation. Please try again.",
        status: "error",
        duration: 3000,
        isClosable: true,
      });
    }
  };

  const handleRefresh = () => {
    pushEvent("refresh_sessions", {});
    toast({
      title: "Refreshed",
      description: "Investigation list has been updated.",
      status: "info",
      duration: 2000,
      isClosable: true,
    });
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  };

  // Sort session data for recent sessions
  const recentSessionsData = recentSessions
    .map(sessionId => state.sessions?.find(s => s.id === sessionId))
    .filter(Boolean);

  // Filter out sessions already in recent list
  const otherSessions = state.sessions
    ? state.sessions.filter(session => !recentSessions.includes(session.id))
    : [];

  return (
    <Container maxW="container.xl" py={8}>
      <Box textAlign="center" mb={8}>
        <Heading as="h1" size="2xl" mb={2} color="brand.500">
          Area 51 Investigations
        </Heading>
        <Text fontSize="lg" color="gray.400">
          Uncover the truth behind humanity's most guarded secrets
        </Text>
        <Text fontSize="sm" color="gray.500" mt={2}>
          Select an investigation to join or create a new one below
        </Text>
        <HStack justify="center" mt={1} spacing={4}>
          <Badge colorScheme="blue" p={1}>Press Enter to create a new investigation</Badge>
          <Badge colorScheme="green" p={1}>Press Esc during investigation to return to this list</Badge>
        </HStack>
      </Box>

      <Box 
        p={6} 
        mb={8} 
        borderRadius="md" 
        bg="area51.800" 
        boxShadow="xl"
        borderWidth="1px"
        borderColor="area51.600"
      >
        <Heading as="h3" size="md" mb={4} color="white">
          <Icon as={FiPlusCircle} mr={2} />
          Start a New Investigation
        </Heading>
        <HStack>
          <Input
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Enter a topic for your investigation (e.g., 'missing scientists', 'strange signals')"
            size="md"
            bg="whiteAlpha.100"
            _hover={{ bg: "whiteAlpha.200" }}
            _focus={{ bg: "whiteAlpha.200", borderColor: "brand.500" }}
            color="white"
            flex="1"
          />
          <Button 
            leftIcon={<FiPlusCircle />}
            colorScheme="brand" 
            onClick={handleCreateSession}
            size="md"
          >
            Create
          </Button>
          <Button
            leftIcon={<FiRefreshCw />}
            variant="outline"
            colorScheme="whiteAlpha"
            onClick={handleRefresh}
            size="md"
          >
            Refresh
          </Button>
        </HStack>
      </Box>

      {recentSessionsData.length > 0 && (
        <Box mb={8}>
          <Heading as="h2" size="lg" mb={4} color="alien.400">
            <Icon as={FiClock} mr={2} />
            Recently Visited Investigations
          </Heading>
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={6}>
            {recentSessionsData.map((session) => (
              <Card 
                key={session.id} 
                bg="area51.900" 
                borderRadius="md" 
                borderLeftWidth="4px"
                borderLeftColor="alien.500"
                overflow="hidden"
                variant="outline"
                borderColor="area51.700"
                _hover={{ transform: "translateY(-4px)", shadow: "lg" }}
                transition="all 0.2s"
              >
                <CardBody>
                  <Badge colorScheme="green" mb={2}>Recent</Badge>
                  <Heading as="h3" size="md" mb={2} color="white">
                    {session.title}
                  </Heading>
                  <Text color="gray.300" noOfLines={2} mb={3}>
                    {session.description}
                  </Text>
                  <Text fontSize="sm" color="gray.500">
                    <Icon as={FiFileText} mr={1} />
                    Created: {formatDate(session.created_at)}
                  </Text>
                </CardBody>
                <CardFooter pt={0}>
                  <Button 
                    colorScheme="alien" 
                    width="full"
                    leftIcon={<FiUserPlus />}
                    onClick={() => onSessionSelect(session.id)}
                  >
                    Resume Investigation
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </SimpleGrid>
        </Box>
      )}

      <Box>
        <Heading as="h2" size="lg" mb={4} color="brand.400">
          Available Investigations
        </Heading>
        {otherSessions.length > 0 ? (
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={6}>
            {otherSessions.map((session) => (
              <Card 
                key={session.id} 
                bg="area51.900" 
                borderRadius="md"
                variant="outline"
                borderColor="area51.700"
                _hover={{ transform: "translateY(-4px)", shadow: "lg" }}
                transition="all 0.2s"
              >
                <CardBody>
                  <Heading as="h3" size="md" mb={2} color="white">
                    {session.title}
                  </Heading>
                  <Text color="gray.300" noOfLines={2} mb={3}>
                    {session.description}
                  </Text>
                  <Text fontSize="sm" color="gray.500">
                    <Icon as={FiFileText} mr={1} />
                    Created: {formatDate(session.created_at)}
                  </Text>
                </CardBody>
                <CardFooter pt={0}>
                  <Button 
                    colorScheme="brand" 
                    width="full"
                    leftIcon={<FiUserPlus />}
                    onClick={() => onSessionSelect(session.id)}
                  >
                    Join Investigation
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </SimpleGrid>
        ) : (
          <Box textAlign="center" p={8} bg="whiteAlpha.100" borderRadius="md">
            <Text color="gray.400">No investigations found. Create a new one to start!</Text>
          </Box>
        )}
      </Box>
    </Container>
  );
};

export default SessionList;