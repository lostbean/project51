import React, { useState, useRef } from "react";
import { useLiveState } from "../react_live_state";
import {
  Box,
  Button,
  Container,
  Flex,
  Heading,
  Input,
  Text,
  Badge,
  VStack,
  HStack,
  IconButton,
  List,
  ListItem,
  Card,
  CardBody,
  useDisclosure,
  Tooltip,
  SimpleGrid,
} from "@chakra-ui/react";

// Import components from their specific packages to avoid import issues
import { Divider } from "@chakra-ui/react";
import { useToast } from "@chakra-ui/react";
import { Icon } from "@chakra-ui/react";
import {
  Drawer,
  DrawerBody,
  DrawerFooter,
  DrawerHeader,
  DrawerOverlay,
  DrawerContent,
  DrawerCloseButton,
} from "@chakra-ui/react";
import {
  AlertDialog,
  AlertDialogBody,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogContent,
  AlertDialogOverlay,
} from "@chakra-ui/react";

// We'll use a regular icon component instead of ListIcon
import { CheckCircleIcon } from "@chakra-ui/icons";
import {
  FiArrowLeft,
  FiSend,
  FiInfo,
  FiFileText,
  FiSearch,
  FiCheckCircle,
} from "react-icons/fi";

const Game = ({ socket, sessionId, onBackToList }) => {
  const [input, setInput] = useState("");
  const [state, pushEvent] = useLiveState(socket, {});
  const toast = useToast();
  const narrativeRef = useRef(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const {
    isOpen: isBackConfirmOpen,
    onOpen: onBackConfirmOpen,
    onClose: onBackConfirmClose,
  } = useDisclosure();

  const scrollToBottom = () => {
    if (narrativeRef.current) {
      narrativeRef.current.scrollTop = narrativeRef.current.scrollHeight;
    }
  };

  // Handle back navigation with confirmation if user has typed something
  const handleBackClick = () => {
    if (input.trim()) {
      // If the user has typed something, confirm before going back
      onBackConfirmOpen();
    } else {
      // Otherwise go back directly
      onBackToList();
    }
  };

  // Add keyboard shortcut for Escape key to navigate back
  React.useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === "Escape") {
        handleBackClick();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [input]);

  const onButtonClick = (event) => {
    event.preventDefault();
    if (input) {
      pushEvent("new_input", { input: input });
      setInput("");

      // After sending input, show a toast notification
      toast({
        title: "Input Sent",
        description: "The Area 51 AI is processing your investigation...",
        status: "info",
        duration: 2000,
        isClosable: true,
      });

      // Scroll to bottom after state updates
      setTimeout(scrollToBottom, 500);
    }
  };

  let narrative = "...";
  if (state.game_session) {
    narrative = state.game_session.narrative;
  }

  let title = "Area 51 Investigation";
  let description = "";
  if (state.game_session) {
    if (state.game_session.title) {
      title = state.game_session.title;
    }
    if (state.game_session.description) {
      description = state.game_session.description;
    }
  }

  return (
    <Container maxW="container.xl" py={4}>
      <HStack justifyContent="space-between" mb={4}>
        <Tooltip label="Back to investigation list (Esc)">
          <IconButton
            icon={<FiArrowLeft />}
            onClick={handleBackClick}
            aria-label="Back to investigations"
            variant="outline"
            colorScheme="whiteAlpha"
            size="md"
          />
        </Tooltip>
        <Heading as="h1" size="xl" color="brand.500">
          {title}
        </Heading>
        <Tooltip label="View investigation details">
          <IconButton
            icon={<FiInfo />}
            onClick={onOpen}
            aria-label="View details"
            variant="outline"
            colorScheme="whiteAlpha"
            size="md"
          />
        </Tooltip>
      </HStack>

      {description && (
        <Text fontStyle="italic" mb={4} color="gray.400" textAlign="center">
          {description}
        </Text>
      )}

      <Box
        ref={narrativeRef}
        bg="area51.900"
        p={4}
        borderRadius="sm"
        borderWidth="1px"
        borderColor="terminal.700"
        mb={4}
        height="60vh"
        overflowY="auto"
        position="relative"
        boxShadow="inset 0 0 10px rgba(0, 0, 0, 0.5)"
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
        <Text
          whiteSpace="pre-line"
          color="terminal.100"
          fontFamily="mono"
          fontSize="md"
          sx={{
            caretColor: "terminal.500",
            "&::after": {
              content: "'_'",
              color: "terminal.400",
              animation: "blink 1s step-end infinite",
              opacity: 1,
            },
          }}
        >
          {narrative}
        </Text>
      </Box>

      <Flex as="form" onSubmit={onButtonClick}>
        <Input
          value={input}
          onChange={(ev) => setInput(ev.target.value)}
          placeholder="> Enter your observation or action..."
          size="lg"
          bg="area51.900"
          color="terminal.200"
          mr={2}
          fontFamily="mono"
          fontSize="md"
          borderColor="terminal.700"
          borderRadius="sm"
          spellCheck="false"
          autoComplete="off"
          _hover={{ bg: "area51.800", borderColor: "terminal.600" }}
          _focus={{
            bg: "area51.800",
            borderColor: "terminal.500",
            boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
          }}
          sx={{
            caretColor: "terminal.400",
            caretShape: "block",
          }}
        />
        <Button
          type="submit"
          colorScheme="brand"
          size="lg"
          leftIcon={<FiSend />}
          _hover={{
            transform: "translateY(-2px)",
            boxShadow: "terminal",
          }}
          _active={{
            transform: "translateY(1px)",
          }}
        >
          TRANSMIT
        </Button>
      </Flex>

      {/* Clues Section Below Input Bar */}
      {state.clues && state.clues.length > 0 && (
        <Box
          mt={6}
          borderRadius="sm"
          bg="area51.900"
          p={4}
          borderWidth="1px"
          borderColor="terminal.700"
          position="relative"
          boxShadow="inset 0 0 10px rgba(0, 0, 0, 0.5)"
          overflow="hidden"
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
            size="md"
            mb={3}
            color="terminal.400"
            display="flex"
            alignItems="center"
            fontFamily="heading"
            letterSpacing="1px"
            textTransform="uppercase"
            borderBottom="1px solid"
            borderColor="terminal.700"
            pb={2}
          >
            <Icon as={FiSearch} mr={2} />
            <Text
              as="span"
              className="blink"
              color="terminal.500"
              mr={1}
              sx={{
                animation: "flicker 3s infinite alternate-reverse",
              }}
            >
              [*]
            </Text>
            Discovered Evidence ({state.clues.length})
          </Heading>
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={3}>
            {state.clues.map((clue, index) => (
              <Card
                key={index}
                bg="area51.800"
                borderLeftWidth="2px"
                borderLeftColor="terminal.500"
                borderRadius="sm"
                _hover={{
                  transform: "translateY(-2px)",
                  boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
                  borderLeftColor: "terminal.400",
                }}
                transition="all 0.2s"
                size="sm"
              >
                <CardBody py={2} px={3}>
                  <HStack align="start" spacing={2}>
                    <Icon
                      as={FiCheckCircle}
                      color="terminal.500"
                      mt={1}
                      sx={{
                        filter: "drop-shadow(0 0 2px rgba(0, 230, 58, 0.4))",
                      }}
                    />
                    <Text color="terminal.200" fontSize="sm" fontFamily="mono">
                      {clue.content}
                    </Text>
                  </HStack>
                </CardBody>
              </Card>
            ))}
          </SimpleGrid>
        </Box>
      )}

      {/* Investigation Details Drawer */}
      <Drawer isOpen={isOpen} placement="right" onClose={onClose} size="md">
        <DrawerOverlay bg="rgba(0, 10, 2, 0.8)" backdropFilter="blur(2px)" />
        <DrawerContent
          bg="area51.800"
          color="terminal.200"
          borderLeft="1px solid"
          borderColor="terminal.700"
          boxShadow="-5px 0 15px rgba(0, 0, 0, 0.5)"
        >
          <DrawerCloseButton
            color="terminal.400"
            _hover={{ color: "terminal.300" }}
          />
          <DrawerHeader
            borderBottomWidth="1px"
            borderColor="terminal.700"
            fontFamily="heading"
            letterSpacing="1px"
            bg="area51.900"
          >
            <Heading
              size="lg"
              color="terminal.500"
              textTransform="uppercase"
              letterSpacing="2px"
              display="flex"
              alignItems="center"
            >
              <Box as="span" mr={2}>
                [{" "}
              </Box>
              Investigation Details
              <Box as="span" ml={2}>
                {" "}
                ]
              </Box>
            </Heading>
          </DrawerHeader>

          <DrawerBody fontFamily="mono">
            <VStack align="stretch" spacing={6}>
              <Box
                bg="area51.900"
                p={4}
                borderRadius="sm"
                borderWidth="1px"
                borderColor="terminal.700"
                boxShadow="inset 0 0 10px rgba(0, 0, 0, 0.5)"
              >
                <Heading
                  size="md"
                  mb={3}
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
                  Mission Brief
                </Heading>
                <Text
                  color="terminal.200"
                  fontFamily="mono"
                  sx={{
                    padding: "0.5rem",
                    background: "rgba(0, 10, 2, 0.4)",
                    borderLeft: "2px solid",
                    borderColor: "terminal.600",
                  }}
                >
                  {description}
                </Text>
              </Box>

              <Divider borderColor="terminal.700" opacity={0.5} />

              <Box
                bg="area51.900"
                p={4}
                borderRadius="sm"
                borderWidth="1px"
                borderColor="terminal.700"
                boxShadow="inset 0 0 10px rgba(0, 0, 0, 0.5)"
              >
                <Heading
                  size="md"
                  mb={3}
                  color="terminal.400"
                  display="flex"
                  alignItems="center"
                  textTransform="uppercase"
                  letterSpacing="1px"
                  borderBottom="1px solid"
                  borderColor="terminal.700"
                  pb={2}
                >
                  <Icon as={FiSearch} mr={2} />
                  <Text as="span" color="terminal.500" mr={1}>
                    [*]
                  </Text>
                  Discovered Evidence
                </Heading>
                {state.clues && state.clues.length > 0 ? (
                  <List spacing={3}>
                    {state.clues.map((clue, index) => (
                      <ListItem key={index}>
                        <Card
                          bg="area51.800"
                          borderLeftWidth="2px"
                          borderLeftColor="terminal.500"
                          borderRadius="sm"
                          mb={2}
                          _hover={{
                            transform: "translateY(-2px)",
                            boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
                          }}
                          transition="all 0.2s"
                        >
                          <CardBody py={3}>
                            <HStack align="start">
                              <Icon
                                as={FiCheckCircle}
                                color="terminal.500"
                                mt={1}
                                sx={{
                                  filter:
                                    "drop-shadow(0 0 2px rgba(0, 230, 58, 0.4))",
                                }}
                              />
                              <Text
                                color="terminal.200"
                                fontFamily="mono"
                                fontSize="sm"
                              >
                                {clue.content}
                              </Text>
                            </HStack>
                          </CardBody>
                        </Card>
                      </ListItem>
                    ))}
                  </List>
                ) : (
                  <Text
                    color="terminal.600"
                    fontFamily="mono"
                    p={3}
                    borderWidth="1px"
                    borderStyle="dashed"
                    borderColor="terminal.700"
                    borderRadius="sm"
                    fontSize="sm"
                  >
                    <Icon as={FiInfo} mr={2} />
                    No evidence discovered yet. Continue your investigation to
                    uncover the truth.
                  </Text>
                )}
              </Box>
            </VStack>
          </DrawerBody>

          <DrawerFooter
            borderTopWidth="1px"
            borderColor="terminal.700"
            bg="area51.900"
          >
            <Button
              variant="outline"
              mr={3}
              onClick={onClose}
              size="md"
              borderColor="terminal.600"
              color="terminal.400"
              _hover={{
                color: "terminal.300",
                boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
              }}
            >
              [ CLOSE ]
            </Button>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>

      {/* Confirmation Dialog for Going Back */}
      <AlertDialog
        isOpen={isBackConfirmOpen}
        leastDestructiveRef={React.useRef()}
        onClose={onBackConfirmClose}
      >
        <AlertDialogOverlay
          bg="rgba(0, 10, 2, 0.8)"
          backdropFilter="blur(2px)"
        />
        <AlertDialogContent
          bg="area51.800"
          color="terminal.200"
          borderWidth="1px"
          borderColor="terminal.700"
          borderRadius="sm"
          boxShadow="0 0 20px rgba(0, 0, 0, 0.6)"
          maxW="md"
        >
          <AlertDialogHeader
            fontSize="lg"
            fontWeight="bold"
            fontFamily="heading"
            color="terminal.500"
            textTransform="uppercase"
            letterSpacing="1px"
            borderBottomWidth="1px"
            borderColor="terminal.700"
            bg="area51.900"
            display="flex"
            alignItems="center"
          >
            <Box as="span" mr={2}>
              [{" "}
            </Box>
            WARNING: Exit Investigation
            <Box as="span" ml={2}>
              {" "}
              ]
            </Box>
          </AlertDialogHeader>

          <AlertDialogBody
            fontFamily="mono"
            py={6}
            sx={{
              position: "relative",
              "&::before": {
                content: "''",
                position: "absolute",
                top: 0,
                left: 0,
                width: "4px",
                height: "100%",
                background: "rgba(255, 50, 50, 0.4)",
              },
            }}
          >
            <Text color="terminal.300" fontSize="md" lineHeight="1.5">
              You have unsaved input. Are you sure you want to leave this
              investigation?
              <Text
                as="span"
                color="terminal.500"
                fontWeight="bold"
                display="block"
                mt={2}
              >
                WARNING: Your input will be lost.
              </Text>
            </Text>
          </AlertDialogBody>

          <AlertDialogFooter
            borderTopWidth="1px"
            borderColor="terminal.700"
            bg="area51.900"
          >
            <Button
              onClick={onBackConfirmClose}
              variant="outline"
              size="md"
              borderColor="terminal.600"
              color="terminal.400"
              _hover={{
                color: "terminal.300",
                boxShadow: "0 0 10px rgba(0, 230, 58, 0.2)",
              }}
            >
              [ CONTINUE INVESTIGATION ]
            </Button>
            <Button
              bg="rgba(180, 50, 50, 0.2)"
              color="red.300"
              borderWidth="1px"
              borderColor="red.600"
              _hover={{
                bg: "rgba(180, 50, 50, 0.3)",
                boxShadow: "0 0 10px rgba(255, 50, 50, 0.4)",
              }}
              onClick={() => {
                onBackConfirmClose();
                onBackToList();
              }}
              ml={3}
            >
              [ ABORT MISSION ]
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Container>
  );
};

export default Game;

