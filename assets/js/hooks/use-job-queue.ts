import { useState, useEffect, useCallback } from 'react';
import { MysteryGenerationJob, JobUpdate, JobQueueData } from '../types/job';

interface UseJobQueueOptions {
  userId: string;
  socketUrl?: string;
}

interface UseJobQueueReturn {
  jobs: JobQueueData;
  isConnected: boolean;
  cancelJob: (jobId: number) => void;
  refreshJobs: () => void;
  error: string | null;
}

export const useJobQueue = ({ 
  userId, 
  socketUrl = "ws://localhost:4000/socket" 
}: UseJobQueueOptions): UseJobQueueReturn => {
  const [jobs, setJobs] = useState<JobQueueData>({ running: [], completed: [] });
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [channel, setChannel] = useState<any>(null);

  // Initialize Phoenix Channel connection
  useEffect(() => {
    if (!userId) return;

    const initializeConnection = async () => {
      try {
        // Import Phoenix dynamically since it might not be available during SSR
        const { Socket } = await import('phoenix');
        
        const phoenixSocket = new Socket(socketUrl, {
          params: {},
          logger: (kind: string, msg: string, data: any) => {
            console.log(`Phoenix ${kind}: ${msg}`, data);
          }
        });

        phoenixSocket.connect();

        const jobChannel = phoenixSocket.channel(`job_updates:${userId}`, {});

        jobChannel.join()
          .receive("ok", (resp) => {
            console.log("Joined job updates channel", resp);
            setIsConnected(true);
            setError(null);
          })
          .receive("error", (resp) => {
            console.error("Unable to join job updates channel", resp);
            setError("Failed to connect to job updates");
            setIsConnected(false);
          });

        // Handle initial jobs data
        jobChannel.on("initial_jobs", (payload) => {
          console.log("Received initial jobs", payload);
          setJobs({
            running: payload.running || [],
            completed: payload.completed || []
          });
        });

        // Handle real-time job updates
        jobChannel.on("job_update", (update: JobUpdate) => {
          console.log("Received job update", update);
          setJobs(prevJobs => updateJobInState(prevJobs, update));
        });

        // Handle connection state changes
        phoenixSocket.onOpen(() => {
          setIsConnected(true);
          setError(null);
        });

        phoenixSocket.onClose(() => {
          setIsConnected(false);
        });

        phoenixSocket.onError((error) => {
          console.error("Phoenix socket error", error);
          setError("Connection error");
          setIsConnected(false);
        });

        setSocket(phoenixSocket);
        setChannel(jobChannel);

        // Cleanup function
        return () => {
          jobChannel.leave();
          phoenixSocket.disconnect();
        };
      } catch (err) {
        console.error("Failed to initialize job queue connection", err);
        setError("Failed to initialize connection");
      }
    };

    const cleanup = initializeConnection();
    
    // Return cleanup function
    return () => {
      cleanup?.then(cleanupFn => cleanupFn?.());
    };
  }, [userId, socketUrl]);

  // Update job in state based on update
  const updateJobInState = (prevJobs: JobQueueData, update: JobUpdate): JobQueueData => {
    const jobId = update.job_id;
    
    // Find the job in running or completed arrays
    let targetJob: MysteryGenerationJob | undefined;
    let isInRunning = false;
    
    targetJob = prevJobs.running.find(job => job.id === jobId);
    if (targetJob) {
      isInRunning = true;
    } else {
      targetJob = prevJobs.completed.find(job => job.id === jobId);
    }

    if (!targetJob) {
      // Job not found, this might be a new job - refresh to get latest state
      return prevJobs;
    }

    // Create updated job
    const updatedJob: MysteryGenerationJob = {
      ...targetJob,
      status: update.status,
      result: update.result || targetJob.result,
      error_message: update.error || targetJob.error_message,
      updated_at: new Date().toISOString(),
    };

    // Determine where the job should be based on its new status
    const shouldBeInRunning = update.status === 'pending' || update.status === 'running';

    if (isInRunning && shouldBeInRunning) {
      // Job stays in running array
      return {
        ...prevJobs,
        running: prevJobs.running.map(job => 
          job.id === jobId ? updatedJob : job
        )
      };
    } else if (isInRunning && !shouldBeInRunning) {
      // Job moves from running to completed
      return {
        running: prevJobs.running.filter(job => job.id !== jobId),
        completed: [updatedJob, ...prevJobs.completed].slice(0, 10) // Keep only 10 most recent
      };
    } else if (!isInRunning && shouldBeInRunning) {
      // Job moves from completed to running (rare, but possible if restarted)
      return {
        running: [updatedJob, ...prevJobs.running],
        completed: prevJobs.completed.filter(job => job.id !== jobId)
      };
    } else {
      // Job stays in completed array
      return {
        ...prevJobs,
        completed: prevJobs.completed.map(job => 
          job.id === jobId ? updatedJob : job
        )
      };
    }
  };

  // Cancel a job
  const cancelJob = useCallback((jobId: number) => {
    if (channel) {
      channel.push("cancel_job", { job_id: jobId })
        .receive("ok", (resp) => {
          console.log("Job cancelled", resp);
        })
        .receive("error", (resp) => {
          console.error("Failed to cancel job", resp);
          setError("Failed to cancel job");
        });
    }
  }, [channel]);

  // Refresh jobs
  const refreshJobs = useCallback(() => {
    if (channel) {
      channel.push("get_jobs", {})
        .receive("ok", (resp) => {
          console.log("Jobs refreshed", resp);
          if (resp.jobs) {
            setJobs({
              running: resp.jobs.running || [],
              completed: resp.jobs.completed || []
            });
          }
        })
        .receive("error", (resp) => {
          console.error("Failed to refresh jobs", resp);
          setError("Failed to refresh jobs");
        });
    }
  }, [channel]);

  return {
    jobs,
    isConnected,
    cancelJob,
    refreshJobs,
    error
  };
};