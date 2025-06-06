export interface MysteryGenerationJob {
  id: number;
  title: string;
  theme: string;
  difficulty: string;
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';
  user_id: string;
  oban_job_id?: number;
  result?: {
    title: string;
    description: string;
    solution: string;
    starting_narrative: string;
  };
  error_message?: string;
  progress: number;
  inserted_at: string;
  updated_at: string;
}

export interface JobUpdate {
  job_id: number;
  status: MysteryGenerationJob['status'];
  result?: MysteryGenerationJob['result'];
  error?: string;
  completed_at?: string;
  failed_at?: string;
}

export interface JobQueueData {
  running: MysteryGenerationJob[];
  completed: MysteryGenerationJob[];
}