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
import UserMenu from "./user-menu";
import MysteryGenerationButton from "./mystery-generation-button";
import { useAuth } from "../auth/use-auth";

// Import components from their specific packages to avoid import issues
import { useToast } from "@chakra-ui/react";
import { Divider } from "@chakra-ui/react";
import {
  FiPlusCircle,
  FiClock,
  FiUserPlus,
  FiFileText,
  FiInfo,
} from "react-icons/fi";

const SessionList = ({ socket, onSessionSelect, recentSessions = [], jobManagementSocket }) => {
  const [state, pushEvent] = useLiveState(socket, { sessions: [] });
  const toast = useToast();
  const { user } = useAuth();


  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  };

  // Sort session data for recent sessions
  const recentSessionsData = recentSessions
    .map((sessionId) => state.sessions?.find((s) => s.id === sessionId))
    .filter(Boolean);

  // Filter out sessions already in recent list
  const otherSessions = state.sessions
    ? state.sessions.filter((session) => !recentSessions.includes(session.id))
    : [];

  return (
    <Container maxW="container.xl" py={8}>
      <Box textAlign="right" mb={4}>
        <UserMenu />
      </Box>
      <Box
        textAlign="center"
        mb={8}
        sx={{
          position: "relative",
          "&::after": {
            content: "''",
            position: "absolute",
            bottom: "-20px",
            left: "50%",
            transform: "translateX(-50%)",
            width: "80%",
            height: "1px",
            background:
              "linear-gradient(to right, rgba(0, 230, 58, 0), rgba(0, 230, 58, 0.4), rgba(0, 230, 58, 0))",
          },
        }}
      >
        <Heading
          as="h1"
          size="2xl"
          mb={2}
          color="terminal.500"
          textTransform="uppercase"
          letterSpacing="4px"
          fontFamily="heading"
          textShadow="0 0 10px rgba(0, 230, 58, 0.4)"
          sx={{
            span: {
              animation: "flicker 4s infinite alternate-reverse",
            },
          }}
        >
          <Box as="span" fontSize="4xl" mr={2}>
            &#9733;
          </Box>
          Area 51 Investigations
          <Box as="span" fontSize="4xl" ml={2}>
            &#9733;
          </Box>
        </Heading>
        <Text
          fontSize="lg"
          color="terminal.300"
          letterSpacing="1px"
          fontFamily="mono"
        >
          Uncover the truth behind humanity's most guarded secrets
        </Text>
        <Text fontSize="sm" color="terminal.600" mt={3} fontFamily="mono">
          Select an investigation to join or use AI to generate a new one below
        </Text>
        <HStack justify="center" mt={3} spacing={4}>
          <Badge
            bg="rgba(0, 230, 58, 0.1)"
            color="terminal.400"
            p={1}
            borderWidth="1px"
            borderColor="terminal.700"
            fontFamily="mono"
          >
            Use AI Mystery Generator to create new investigations
          </Badge>
          <Badge
            bg="rgba(0, 230, 58, 0.1)"
            color="terminal.400"
            p={1}
            borderWidth="1px"
            borderColor="terminal.700"
            fontFamily="mono"
          >
            Press Esc during investigation to return to this list
          </Badge>
        </HStack>
      </Box>

      <Box
        p={6}
        mb={8}
        borderRadius="sm"
        bg="area51.900"
        boxShadow="inset 0 0 10px rgba(0, 0, 0, 0.5)"
        borderWidth="1px"
        borderColor="terminal.700"
        position="relative"
        _before={{
          content: "''",
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: "2px",
          background: "terminal.600",
          opacity: 0.5,
          zIndex: 1,
        }}
      >
        <Heading
          as="h3"
          size="md"
          mb={4}
          color="terminal.400"
          display="flex"
          alignItems="center"
          textTransform="uppercase"
          letterSpacing="1px"
          borderBottom="1px solid"
          borderColor="terminal.700"
          pb={2}
        >
          <Icon as={FiPlusCircle} mr={2} />
          <Text as="span" color="terminal.500" mr={1}>
            [*]
          </Text>
          AI Mystery Generator
        </Heading>
        
        <HStack justify="space-between" align="center" mb={4}>
          <VStack spacing={0} align="start">
            <Text color="terminal.400" fontSize="md" fontWeight="bold" textTransform="uppercase" letterSpacing="1px">
              Initialize New Investigation
            </Text>
            <Text color="terminal.600" fontSize="sm">
              Let the AI create a mystery investigation for you. Generated investigations will automatically appear in your files.
            </Text>
          </VStack>
          {user && jobManagementSocket && (
            <MysteryGenerationButton
              socket={jobManagementSocket}
              onMysteryGenerated={(jobId) => {
                toast({
                  title: "Mystery Generation Started",
                  description: "Check the job queue sidebar for progress. Completed mysteries will be added to your files automatically.",
                  status: "info",
                  duration: 4000,
                  isClosable: true,
                });
              }}
            />
          )}
        </HStack>
        
      </Box>

      {recentSessionsData.length > 0 && (
        <Box mb={8} position="relative">
          <Heading
            as="h2"
            size="lg"
            mb={4}
            color="terminal.400"
            display="flex"
            alignItems="center"
            textTransform="uppercase"
            letterSpacing="1px"
            borderBottom="1px solid"
            borderColor="terminal.700"
            pb={2}
          >
            <Icon as={FiClock} mr={2} />
            <Text as="span" color="terminal.500" mr={1}>
              [*]
            </Text>
            Recently Accessed Files
          </Heading>
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={6}>
            {recentSessionsData.map((session) => (
              <Card
                key={session.id}
                bg="area51.900"
                borderRadius="sm"
                borderLeftWidth="2px"
                borderLeftColor="terminal.500"
                overflow="hidden"
                borderWidth="1px"
                borderColor="terminal.700"
                _hover={{
                  transform: "translateY(-4px)",
                  boxShadow: "0 0 15px rgba(0, 230, 58, 0.2)",
                }}
                position="relative"
                transition="all 0.2s"
              >
                <CardBody fontFamily="mono">
                  <Badge
                    bg="rgba(0, 230, 58, 0.1)"
                    color="terminal.400"
                    mb={2}
                    borderWidth="1px"
                    borderColor="terminal.600"
                    fontFamily="mono"
                    fontSize="xs"
                  >
                    Recent Access
                  </Badge>
                  <Heading
                    as="h3"
                    size="md"
                    mb={2}
                    color="terminal.200"
                    fontFamily="heading"
                    letterSpacing="1px"
                  >
                    {session.title}
                  </Heading>
                  <Text
                    color="terminal.300"
                    noOfLines={2}
                    mb={3}
                    fontFamily="mono"
                    fontSize="sm"
                    sx={{
                      padding: "0.5rem",
                      background: "rgba(0, 10, 2, 0.4)",
                      borderLeft: "2px solid",
                      borderColor: "terminal.600",
                    }}
                  >
                    {session.description}
                  </Text>
                  <Text fontSize="xs" color="terminal.600" fontFamily="mono">
                    <Icon as={FiFileText} mr={1} />
                    FILE-DATE: {formatDate(session.created_at)}
                  </Text>
                </CardBody>
                <CardFooter
                  pt={0}
                  bg="area51.800"
                  borderTop="1px solid"
                  borderColor="terminal.700"
                >
                  <Button
                    colorScheme="brand"
                    width="full"
                    leftIcon={<FiUserPlus />}
                    onClick={() => onSessionSelect(session.id)}
                    _hover={{
                      transform: "translateY(-2px)",
                      boxShadow: "terminal",
                    }}
                    _active={{
                      transform: "translateY(1px)",
                    }}
                  >
                    ACCESS FILE
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </SimpleGrid>
        </Box>
      )}

      <Box>
        <Heading
          as="h2"
          size="lg"
          mb={4}
          color="terminal.400"
          display="flex"
          alignItems="center"
          textTransform="uppercase"
          letterSpacing="1px"
          borderBottom="1px solid"
          borderColor="terminal.700"
          pb={2}
        >
          <Icon as={FiFileText} mr={2} />
          <Text as="span" color="terminal.500" mr={1}>
            [*]
          </Text>
          Classified Documents
        </Heading>
        {otherSessions.length > 0 ? (
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={6}>
            {otherSessions.map((session) => (
              <Card
                key={session.id}
                bg="area51.900"
                borderRadius="sm"
                borderWidth="1px"
                borderColor="terminal.700"
                _hover={{
                  transform: "translateY(-4px)",
                  boxShadow: "0 0 15px rgba(0, 230, 58, 0.15)",
                }}
                transition="all 0.2s"
                position="relative"
                overflow="hidden"
                _after={{
                  content: "''",
                  position: "absolute",
                  top: 0,
                  right: 0,
                  width: "15px",
                  height: "15px",
                  borderRight: "15px solid",
                  borderRightColor: "terminal.700",
                  borderTop: "15px solid transparent",
                  borderBottom: "15px solid transparent",
                  transform: "rotate(45deg) translate(10px, -10px)",
                }}
              >
                <CardBody fontFamily="mono">
                  <Heading
                    as="h3"
                    size="md"
                    mb={2}
                    color="terminal.200"
                    fontFamily="heading"
                    letterSpacing="1px"
                  >
                    {session.title}
                  </Heading>
                  <Text
                    color="terminal.300"
                    noOfLines={2}
                    mb={3}
                    fontFamily="mono"
                    fontSize="sm"
                    sx={{
                      padding: "0.5rem",
                      background: "rgba(0, 10, 2, 0.4)",
                      borderLeft: "2px solid",
                      borderColor: "terminal.600",
                    }}
                  >
                    {session.description}
                  </Text>
                  <Text fontSize="xs" color="terminal.600" fontFamily="mono">
                    <Icon as={FiFileText} mr={1} />
                    FILE-DATE: {formatDate(session.created_at)}
                  </Text>
                </CardBody>
                <CardFooter
                  pt={0}
                  bg="area51.800"
                  borderTop="1px solid"
                  borderColor="terminal.700"
                >
                  <Button
                    colorScheme="brand"
                    width="full"
                    leftIcon={<FiUserPlus />}
                    onClick={() => onSessionSelect(session.id)}
                    _hover={{
                      transform: "translateY(-2px)",
                      boxShadow: "terminal",
                    }}
                    _active={{
                      transform: "translateY(1px)",
                    }}
                  >
                    ACCESS FILE
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </SimpleGrid>
        ) : (
          <Box
            textAlign="center"
            p={8}
            bg="area51.900"
            borderWidth="1px"
            borderStyle="dashed"
            borderColor="terminal.700"
            borderRadius="sm"
          >
            <Text color="terminal.600" fontFamily="mono" fontSize="sm">
              <Icon as={FiInfo} mr={2} />
              No classified documents found. Create a new investigation to
              begin.
            </Text>
          </Box>
        )}
      </Box>
    </Container>
  );
};

export default SessionList;
