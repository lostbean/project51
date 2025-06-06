import React, { useState, useEffect } from "react";
import {
  Box,
  Button,
  VStack,
  HStack,
  Text,
  Badge,
  Progress,
  Icon,
  IconButton,
  Tooltip,
  Card,
  CardBody,
  Divider,
  useDisclosure,
  Collapse,
  Spinner,
  Alert,
  AlertIcon,
  AlertTitle,
  AlertDescription,
} from "@chakra-ui/react";
import {
  FiPlay,
  FiCheck,
  FiX,
  FiClock,
  FiAlertCircle,
  FiChevronDown,
  FiChevronUp,
} from "react-icons/fi";
import { Job } from "../types/job";
import { useJobManagement } from "../hooks/use-job-management";

interface JobQueueSidebarProps {
  socket: any;
  onSessionCreated?: (sessionId: number) => void;
}

const JobItem: React.FC<{
  job: Job;
  onCancel: (jobId: number) => void;
}> = ({ job, onCancel }) => {
  const { isOpen, onToggle } = useDisclosure();

  const getStatusIcon = () => {
    switch (job.status) {
      case 'pending':
        return <Icon as={FiClock} color="yellow.400" />;
      case 'running':
        return <Spinner size="sm" color="blue.400" />;
      case 'completed':
        return <Icon as={FiCheck} color="green.400" />;
      case 'failed':
        return <Icon as={FiAlertCircle} color="red.400" />;
      case 'cancelled':
        return <Icon as={FiX} color="gray.400" />;
      default:
        return <Icon as={FiClock} color="gray.400" />;
    }
  };

  const getStatusColor = () => {
    switch (job.status) {
      case 'pending':
        return 'yellow';
      case 'running':
        return 'blue';
      case 'completed':
        return 'green';
      case 'failed':
        return 'red';
      case 'cancelled':
        return 'gray';
      default:
        return 'gray';
    }
  };

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  const canCancel = job.status === 'pending' || job.status === 'running';

  return (
    <Card size="sm" variant="outline" bg="area51.900">
      <CardBody p={3}>
        <VStack spacing={2} align="stretch">
          {/* Job Header */}
          <HStack justify="space-between">
            <HStack spacing={2} flex={1}>
              {getStatusIcon()}
              <VStack spacing={0} align="start" flex={1}>
                <Text fontSize="sm" fontWeight="bold" noOfLines={1}>
                  {job.title}
                </Text>
                <Text fontSize="xs" color="gray.400" noOfLines={1}>
                  {job.theme} • {job.difficulty}
                </Text>
              </VStack>
            </HStack>
            
            <HStack spacing={1}>
              <Badge colorScheme={getStatusColor()} size="sm">
                {job.status}
              </Badge>
              
              {canCancel && (
                <Tooltip label="Cancel job">
                  <IconButton
                    size="xs"
                    icon={<FiX />}
                    onClick={() => onCancel(job.id)}
                    aria-label="Cancel job"
                    variant="ghost"
                    colorScheme="red"
                  />
                </Tooltip>
              )}
              
              {(job.result || job.error_message) && (
                <Tooltip label={isOpen ? "Hide details" : "Show details"}>
                  <IconButton
                    size="xs"
                    icon={isOpen ? <FiChevronUp /> : <FiChevronDown />}
                    onClick={onToggle}
                    aria-label="Toggle details"
                    variant="ghost"
                  />
                </Tooltip>
              )}
            </HStack>
          </HStack>

          {/* Progress Bar for Running Jobs */}
          {job.status === 'running' && (
            <VStack spacing={1} align="stretch">
              <Progress 
                value={job.progress} 
                size="sm" 
                colorScheme="blue"
                bg="area51.800"
              />
              <Text fontSize="xs" color="gray.400" textAlign="center">
                {job.progress}% complete
              </Text>
            </VStack>
          )}

          {/* Timestamp */}
          <Text fontSize="xs" color="gray.500" textAlign="right">
            {formatTime(job.inserted_at)}
          </Text>

          {/* Expandable Details */}
          <Collapse in={isOpen}>
            <VStack spacing={2} align="stretch" pt={2}>
              <Divider />
              
              {job.status === 'completed' && job.result && (
                <Box>
                  <Text fontSize="xs" fontWeight="bold" color="green.400" mb={1}>
                    Generated Mystery:
                  </Text>
                  <Text fontSize="xs" color="gray.300" mb={1}>
                    <strong>Title:</strong> {job.result.title}
                  </Text>
                  <Text fontSize="xs" color="gray.300" noOfLines={3}>
                    <strong>Description:</strong> {job.result.description}
                  </Text>
                </Box>
              )}
              
              {job.status === 'failed' && job.error_message && (
                <Alert status="error" size="sm" bg="red.900" borderRadius="md">
                  <AlertIcon />
                  <Box flex="1">
                    <AlertTitle fontSize="xs">Error:</AlertTitle>
                    <AlertDescription fontSize="xs" noOfLines={2}>
                      {job.error_message}
                    </AlertDescription>
                  </Box>
                </Alert>
              )}
            </VStack>
          </Collapse>
        </VStack>
      </CardBody>
    </Card>
  );
};

const JobQueueSidebar: React.FC<JobQueueSidebarProps> = ({ socket, onSessionCreated }) => {
  const { isOpen: showCompleted, onToggle: toggleCompleted } = useDisclosure({ defaultIsOpen: false });
  
  const { state, actions } = useJobManagement(socket);
  
  // Watch for completed jobs that created sessions and notify parent
  const [lastProcessedSessionId, setLastProcessedSessionId] = useState<number | null>(null);
  
  useEffect(() => {
    if (state?.last_completed_session_id && 
        state.last_completed_session_id !== lastProcessedSessionId && 
        onSessionCreated) {
      onSessionCreated(state.last_completed_session_id);
      setLastProcessedSessionId(state.last_completed_session_id);
    }
  }, [state?.last_completed_session_id, onSessionCreated, lastProcessedSessionId]);
  
  if (!state) {
    return (
      <Box
        w="350px"
        h="100vh"
        bg="area51.800"
        borderLeft="1px solid"
        borderColor="terminal.700"
        position="fixed"
        right={0}
        top={0}
        zIndex={1000}
        display="flex"
        alignItems="center"
        justifyContent="center"
      >
        <VStack spacing={2}>
          <Spinner size="lg" color="terminal.400" />
          <Text color="gray.400">Connecting...</Text>
        </VStack>
      </Box>
    );
  }

  const runningCount = state.running_jobs.length;
  const completedCount = state.completed_jobs.length;
  
  const handleJobCancel = async (jobId: number) => {
    const result = await actions.cancelJob(jobId);
    if (!result.success) {
      console.error('Failed to cancel job:', result.error);
    }
  };

  return (
    <Box
      w="350px"
      h="100vh"
      bg="area51.800"
      borderLeft="1px solid"
      borderColor="terminal.700"
      overflowY="auto"
      position="fixed"
      right={0}
      top={0}
      zIndex={1000}
    >
      <VStack spacing={4} p={4} align="stretch">
        {/* Header */}
        <HStack justify="space-between">
          <VStack spacing={0} align="start">
            <Text fontSize="lg" fontWeight="bold" color="terminal.400">
              Job Queue
            </Text>
            <HStack spacing={2}>
              <Badge colorScheme="green" size="sm">
                Connected
              </Badge>
              {runningCount > 0 && (
                <Badge colorScheme="blue" size="sm">
                  {runningCount} running
                </Badge>
              )}
            </HStack>
          </VStack>
          
        </HStack>

        <Divider />

        {/* Running Jobs Section */}
        <VStack spacing={2} align="stretch">
          <Text fontSize="md" fontWeight="bold" color="terminal.500">
            Active Jobs ({runningCount})
          </Text>
          
          {runningCount === 0 ? (
            <Card variant="outline" bg="area51.900">
              <CardBody p={4} textAlign="center">
                <Icon as={FiPlay} color="gray.400" boxSize={6} mb={2} />
                <Text fontSize="sm" color="gray.400">
                  No active jobs
                </Text>
                <Text fontSize="xs" color="gray.500">
                  Start a mystery generation to see progress here
                </Text>
              </CardBody>
            </Card>
          ) : (
            <VStack spacing={2} align="stretch">
              {state.running_jobs.map((job) => (
                <JobItem key={job.id} job={job} onCancel={handleJobCancel} />
              ))}
            </VStack>
          )}
        </VStack>

        {/* Completed Jobs Section */}
        <VStack spacing={2} align="stretch">
          <HStack justify="space-between">
            <Text fontSize="md" fontWeight="bold" color="terminal.500">
              Recent Jobs ({completedCount})
            </Text>
            {completedCount > 0 && (
              <IconButton
                size="sm"
                icon={showCompleted ? <FiChevronUp /> : <FiChevronDown />}
                onClick={toggleCompleted}
                aria-label="Toggle completed jobs"
                variant="ghost"
              />
            )}
          </HStack>
          
          <Collapse in={showCompleted || completedCount === 0}>
            {completedCount === 0 ? (
              <Card variant="outline" bg="area51.900">
                <CardBody p={4} textAlign="center">
                  <Icon as={FiCheck} color="gray.400" boxSize={6} mb={2} />
                  <Text fontSize="sm" color="gray.400">
                    No completed jobs
                  </Text>
                </CardBody>
              </Card>
            ) : (
              <VStack spacing={2} align="stretch" maxH="300px" overflowY="auto">
                {state.completed_jobs.map((job) => (
                  <JobItem key={job.id} job={job} onCancel={handleJobCancel} />
                ))}
              </VStack>
            )}
          </Collapse>
        </VStack>
      </VStack>
    </Box>
  );
};

export default JobQueueSidebar;