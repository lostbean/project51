import { useLiveState } from '../react_live_state';
import { Job } from '../types/job';

interface JobManagementState {
  running_jobs: Job[];
  completed_jobs: Job[];
  user_id: string;
  username: string;
  error: string | null;
}

interface JobManagementActions {
  generateMystery: (params: {
    theme?: string;
    difficulty?: string;
  }) => Promise<{
    success: boolean;
    job?: Partial<Job>;
    error?: string;
  }>;
  cancelJob: (jobId: number) => Promise<{
    success: boolean;
    message?: string;
    error?: string;
  }>;
  refreshJobs: () => void;
  getJobStatus: (jobId: number) => Promise<{
    success: boolean;
    job?: Job;
    error?: string;
  }>;
}

interface UseJobManagementReturn {
  state: JobManagementState | null;
  actions: JobManagementActions;
}

/**
 * Hook for managing mystery generation jobs via LiveState
 */
export function useJobManagement(socket: any): UseJobManagementReturn {
  const [state, pushEvent] = useLiveState(socket, {
    running_jobs: [],
    completed_jobs: [],
    user_id: '',
    username: '',
    error: null
  });

  const actions: JobManagementActions = {
    async generateMystery(params) {
      try {
        // Don't wait for response since LiveState uses {:noreply, state}
        pushEvent('generate_mystery', {
          theme: params.theme,
          difficulty: params.difficulty || 'medium',
        });
        // Return success immediately
        return { success: true };
      } catch (error) {
        console.error('Failed to generate mystery:', error);
        return {
          success: false,
          error: error instanceof Error ? error.message : 'Failed to generate mystery',
        };
      }
    },

    async cancelJob(jobId) {
      try {
        // Don't wait for response since LiveState uses {:noreply, state}
        pushEvent('cancel_job', {
          job_id: jobId,
        });
        return { success: true };
      } catch (error) {
        console.error('Failed to cancel job:', error);
        return {
          success: false,
          error: error instanceof Error ? error.message : 'Failed to cancel job',
        };
      }
    },

    refreshJobs() {
      pushEvent('refresh_jobs', {});
    },

    async getJobStatus(jobId) {
      try {
        // Don't wait for response since LiveState uses {:noreply, state}
        pushEvent('get_job_status', {
          job_id: jobId,
        });
        return { success: true };
      } catch (error) {
        console.error('Failed to get job status:', error);
        return {
          success: false,
          error: error instanceof Error ? error.message : 'Failed to get job status',
        };
      }
    },
  };

  return {
    state,
    actions,
  };
}