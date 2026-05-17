/**
 * Common TypeScript Types and Interfaces
 */

export interface Lane {
  id: string;
  name: string;
  status: 'healthy' | 'degraded' | 'down';
  taskCount: number;
  successRate: number;
  avgDuration: number;
  responseTime: number;
  lastUpdate: string;
}

export interface DashboardStats {
  totalTasks: number;
  successRate: number;
  avgDuration: number;
  lastUpdate: string;
  lanes: Lane[];
}

export interface ProofDetail {
  task_id: string;
  intent_signal: string;
  routed_lane: string;
  fallback_lane: string;
  risk_level: string;
  status: 'SUCCESS' | 'BLOCKED' | 'TIMEOUT' | 'ERROR';
  gates_passed: string[];
  execution_timestamp: string;
  execution_duration_seconds: number;
  lane_response: {
    status_code: number;
    response_time_ms: number;
    output_length: number;
  };
  proof_path: string;
  proof_summary: string;
}

export interface TaskSubmission {
  intent: string;
  context: string;
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
}

export interface TaskResult {
  task_id: string;
  status: string;
  routed_lane: string;
  message: string;
}

export interface GraphDataPoint {
  timestamp: number;
  value: number;
  label: string;
}

export interface LaneHistory {
  lane: string;
  successRateHistory: GraphDataPoint[];
  responseTimeHistory: GraphDataPoint[];
  taskCountHistory: GraphDataPoint[];
}

export interface AppContextType {
  isOnline: boolean;
  serverUrl: string;
  theme: 'light' | 'dark' | 'auto';
  currentLane: string | null;
}
