import React, { useState } from 'react';
import {
  Button,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalFooter,
  ModalBody,
  ModalCloseButton,
  FormControl,
  FormLabel,
  Input,
  Select,
  VStack,
  useDisclosure,
  useToast,
  Icon,
  HStack,
  Text,
} from '@chakra-ui/react';
import { FiPlay, FiZap } from 'react-icons/fi';

interface MysteryGenerationButtonProps {
  onMysteryGenerated?: (jobId: number) => void;
  userId: string;
  variant?: 'solid' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isDisabled?: boolean;
}

const MysteryGenerationButton: React.FC<MysteryGenerationButtonProps> = ({
  onMysteryGenerated,
  userId,
  variant = 'solid',
  size = 'md',
  isDisabled = false,
}) => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [isLoading, setIsLoading] = useState(false);
  const [theme, setTheme] = useState('');
  const [difficulty, setDifficulty] = useState('medium');
  const toast = useToast();

  const predefinedThemes = [
    'alien technology discovery',
    'unexplained phenomena', 
    'government cover-up',
    'missing scientists',
    'strange signals',
    'unusual biological entities',
  ];

  const difficulties = [
    { value: 'easy', label: 'Easy', description: 'Simple mystery with clear clues' },
    { value: 'medium', label: 'Medium', description: 'Moderate complexity with some ambiguity' },
    { value: 'hard', label: 'Hard', description: 'Complex mystery requiring deep investigation' },
  ];

  const handleGenerate = async () => {
    if (!userId) {
      toast({
        title: 'Authentication Required',
        description: 'Please log in to generate mysteries',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    setIsLoading(true);

    try {
      // Call the backend API to create an async mystery generation job
      const response = await fetch('/api/mysteries/generate-async', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          theme: theme.trim() || undefined, // Use undefined for random theme
          difficulty,
          user_id: userId,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      if (data.error) {
        throw new Error(data.error);
      }

      // Success!
      toast({
        title: 'Mystery Generation Started',
        description: `Your ${difficulty} mystery about "${data.job.theme}" is being generated in the background.`,
        status: 'success',
        duration: 5000,
        isClosable: true,
      });

      // Call the callback if provided
      if (onMysteryGenerated) {
        onMysteryGenerated(data.job.id);
      }

      // Reset form and close modal
      setTheme('');
      setDifficulty('medium');
      onClose();

    } catch (error) {
      console.error('Failed to start mystery generation:', error);
      toast({
        title: 'Generation Failed',
        description: error instanceof Error ? error.message : 'Failed to start mystery generation',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickGenerate = async () => {
    if (!userId) {
      toast({
        title: 'Authentication Required',
        description: 'Please log in to generate mysteries',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    setIsLoading(true);

    try {
      const response = await fetch('/api/mysteries/generate-async', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          difficulty: 'medium',
          user_id: userId,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      if (data.error) {
        throw new Error(data.error);
      }

      toast({
        title: 'Mystery Generation Started',
        description: `A random mystery is being generated in the background.`,
        status: 'success',
        duration: 4000,
        isClosable: true,
      });

      if (onMysteryGenerated) {
        onMysteryGenerated(data.job.id);
      }

    } catch (error) {
      console.error('Failed to start mystery generation:', error);
      toast({
        title: 'Generation Failed',
        description: error instanceof Error ? error.message : 'Failed to start mystery generation',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <HStack spacing={2}>
        {/* Quick Generate Button */}
        <Button
          leftIcon={<Icon as={FiZap} />}
          onClick={handleQuickGenerate}
          isLoading={isLoading}
          loadingText="Starting..."
          variant={variant}
          size={size}
          isDisabled={isDisabled}
          colorScheme="terminal"
        >
          Quick Generate
        </Button>

        {/* Custom Generate Button */}
        <Button
          leftIcon={<Icon as={FiPlay} />}
          onClick={onOpen}
          variant="outline"
          size={size}
          isDisabled={isDisabled}
          colorScheme="terminal"
        >
          Custom
        </Button>
      </HStack>

      {/* Custom Generation Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="md">
        <ModalOverlay />
        <ModalContent bg="area51.800" borderColor="terminal.700">
          <ModalHeader color="terminal.400">Generate Mystery</ModalHeader>
          <ModalCloseButton />
          
          <ModalBody>
            <VStack spacing={4}>
              <FormControl>
                <FormLabel color="terminal.500">Theme</FormLabel>
                <Input
                  placeholder="Leave empty for random theme..."
                  value={theme}
                  onChange={(e) => setTheme(e.target.value)}
                  variant="filled"
                />
                <VStack spacing={1} mt={2} align="stretch">
                  <Text fontSize="xs" color="gray.400">Popular themes:</Text>
                  <HStack spacing={1} flexWrap="wrap">
                    {predefinedThemes.map((predefinedTheme) => (
                      <Button
                        key={predefinedTheme}
                        size="xs"
                        variant="ghost"
                        onClick={() => setTheme(predefinedTheme)}
                        color="terminal.400"
                        _hover={{ color: 'terminal.300' }}
                      >
                        {predefinedTheme}
                      </Button>
                    ))}
                  </HStack>
                </VStack>
              </FormControl>

              <FormControl>
                <FormLabel color="terminal.500">Difficulty</FormLabel>
                <Select
                  value={difficulty}
                  onChange={(e) => setDifficulty(e.target.value)}
                  variant="filled"
                >
                  {difficulties.map((diff) => (
                    <option key={diff.value} value={diff.value}>
                      {diff.label} - {diff.description}
                    </option>
                  ))}
                </Select>
              </FormControl>
            </VStack>
          </ModalBody>

          <ModalFooter>
            <Button
              variant="ghost"
              mr={3}
              onClick={onClose}
              isDisabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              colorScheme="terminal"
              onClick={handleGenerate}
              isLoading={isLoading}
              loadingText="Starting..."
              leftIcon={<Icon as={FiPlay} />}
            >
              Generate Mystery
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default MysteryGenerationButton;