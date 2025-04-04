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
import { Drawer, DrawerBody, DrawerFooter, DrawerHeader, DrawerOverlay, DrawerContent, DrawerCloseButton } from "@chakra-ui/react";
import { AlertDialog, AlertDialogBody, AlertDialogFooter, AlertDialogHeader, AlertDialogContent, AlertDialogOverlay } from "@chakra-ui/react";

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
    onClose: onBackConfirmClose 
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
      if (e.key === 'Escape') {
        handleBackClick();
      }
    };
    
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
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
        <Text
          fontStyle="italic"
          mb={4}
          color="gray.400"
          textAlign="center"
        >
          {description}
        </Text>
      )}

      <Box
        ref={narrativeRef}
        bg="area51.900"
        p={4}
        borderRadius="md"
        borderWidth="1px"
        borderColor="area51.700"
        mb={4}
        height="60vh"
        overflowY="auto"
        css={{
          "&::-webkit-scrollbar": {
            width: "8px",
          },
          "&::-webkit-scrollbar-track": {
            background: "#1A202C",
          },
          "&::-webkit-scrollbar-thumb": {
            background: "#2D3748",
            borderRadius: "4px",
          },
        }}
      >
        <Text whiteSpace="pre-line" color="gray.300">
          {narrative}
        </Text>
      </Box>

      <Flex as="form" onSubmit={onButtonClick}>
        <Input
          value={input}
          onChange={(ev) => setInput(ev.target.value)}
          placeholder="Enter your observation or action..."
          size="lg"
          bg="whiteAlpha.100"
          color="white"
          mr={2}
          _hover={{ bg: "whiteAlpha.200" }}
          _focus={{ bg: "whiteAlpha.200", borderColor: "brand.500" }}
        />
        <Button
          type="submit"
          colorScheme="brand"
          size="lg"
          leftIcon={<FiSend />}
        >
          Submit
        </Button>
      </Flex>
      
      {/* Clues Section Below Input Bar */}
      {state.clues && state.clues.length > 0 && (
        <Box mt={6} borderRadius="md" bg="area51.900" p={4} borderWidth="1px" borderColor="area51.700">
          <Heading size="md" mb={3} color="alien.400" display="flex" alignItems="center">
            <Icon as={FiSearch} mr={2} />
            Discovered Clues ({state.clues.length})
          </Heading>
          <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={3}>
            {state.clues.map((clue, index) => (
              <Card
                key={index}
                bg="area51.800"
                borderLeftWidth="3px"
                borderLeftColor="alien.500"
                _hover={{ transform: "translateY(-2px)", shadow: "md" }}
                transition="all 0.2s"
                size="sm"
              >
                <CardBody py={2} px={3}>
                  <HStack align="start" spacing={2}>
                    <Icon as={FiCheckCircle} color="alien.500" mt={1} />
                    <Text color="gray.300" fontSize="sm">{clue.content}</Text>
                  </HStack>
                </CardBody>
              </Card>
            ))}
          </SimpleGrid>
        </Box>
      )}

      {/* Investigation Details Drawer */}
      <Drawer isOpen={isOpen} placement="right" onClose={onClose} size="md">
        <DrawerOverlay />
        <DrawerContent bg="area51.800" color="white">
          <DrawerCloseButton />
          <DrawerHeader borderBottomWidth="1px" borderColor="area51.700">
            <Heading size="lg" color="brand.500">
              Investigation Details
            </Heading>
          </DrawerHeader>

          <DrawerBody>
            <VStack align="stretch" spacing={6}>
              <Box>
                <Heading size="md" mb={2} color="alien.400">
                  <Icon as={FiFileText} mr={2} />
                  Mission Brief
                </Heading>
                <Text color="gray.300">{description}</Text>
              </Box>

              <Divider />

              <Box>
                <Heading size="md" mb={3} color="alien.400">
                  <Icon as={FiSearch} mr={2} />
                  Discovered Clues
                </Heading>
                {state.clues && state.clues.length > 0 ? (
                  <List spacing={3}>
                    {state.clues.map((clue, index) => (
                      <ListItem key={index}>
                        <Card
                          bg="area51.900"
                          borderLeftWidth="3px"
                          borderLeftColor="alien.500"
                          mb={2}
                        >
                          <CardBody py={3}>
                            <HStack align="start">
                              <Icon
                                as={FiCheckCircle}
                                color="alien.500"
                                mt={1}
                              />
                              <Text color="gray.300">{clue.content}</Text>
                            </HStack>
                          </CardBody>
                        </Card>
                      </ListItem>
                    ))}
                  </List>
                ) : (
                  <Text color="gray.500">
                    No clues discovered yet. Continue your investigation to uncover evidence.
                  </Text>
                )}
              </Box>
            </VStack>
          </DrawerBody>

          <DrawerFooter borderTopWidth="1px" borderColor="area51.700">
            <Button variant="outline" mr={3} onClick={onClose}>
              Close
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
        <AlertDialogOverlay>
          <AlertDialogContent bg="area51.800" color="white">
            <AlertDialogHeader fontSize="lg" fontWeight="bold">
              Exit Investigation
            </AlertDialogHeader>

            <AlertDialogBody>
              You have unsaved input. Are you sure you want to leave this investigation?
              Your input will be lost.
            </AlertDialogBody>

            <AlertDialogFooter>
              <Button 
                onClick={onBackConfirmClose}
                variant="outline"
              >
                Cancel
              </Button>
              <Button 
                colorScheme="red" 
                onClick={() => {
                  onBackConfirmClose();
                  onBackToList();
                }} 
                ml={3}
              >
                Exit Investigation
              </Button>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialogOverlay>
      </AlertDialog>
    </Container>
  );
};

export default Game;