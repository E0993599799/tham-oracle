export type CommandId =
  | 'git-status'
  | 'git-branch'
  | 'git-log'
  | 'tmux-ls'
  | 'tmux-fleet'
  | 'node-version'
  | 'bun-version'
  | 'python-version'
  | '9router-models'
  | 'oracle-v2-health'
  | 'fleet-panes'

export interface CommandOption {
  id: CommandId
  label: string
  description: string
  category: 'git' | 'runtime' | 'process'
  mutating: boolean
}

export interface CommandExecutionSpec {
  executable: string
  args: string[]
  timeoutMs: number
  cwd?: string
  env?: Record<string, string>
}

export const COMMAND_OPTIONS: CommandOption[] = [
  {
    id: 'git-status',
    label: 'Git status',
    description: 'Show branch and working tree status for the repo',
    category: 'git',
    mutating: false,
  },
  {
    id: 'git-branch',
    label: 'Git branch',
    description: 'Show the current branch name',
    category: 'git',
    mutating: false,
  },
  {
    id: 'git-log',
    label: 'Git last commit',
    description: 'Show the latest commit with a short stat summary',
    category: 'git',
    mutating: false,
  },
  {
    id: 'tmux-ls',
    label: 'tmux sessions',
    description: 'List local tmux sessions on the host',
    category: 'process',
    mutating: false,
  },
  {
    id: 'node-version',
    label: 'Node version',
    description: 'Report the installed Node.js version',
    category: 'runtime',
    mutating: false,
  },
  {
    id: 'bun-version',
    label: 'Bun version',
    description: 'Report the installed Bun version',
    category: 'runtime',
    mutating: false,
  },
  {
    id: 'python-version',
    label: 'Python version',
    description: 'Report the installed Python version',
    category: 'runtime',
    mutating: false,
  },
  {
    id: 'tmux-fleet',
    label: 'Fleet panes',
    description: 'List all panes in tham-oracle-stack:fleet-ops',
    category: 'process',
    mutating: false,
  },
  {
    id: '9router-models',
    label: '9router models',
    description: 'List available models from 9router (OpenClaw)',
    category: 'runtime',
    mutating: false,
  },
  {
    id: 'oracle-v2-health',
    label: 'Oracle v2 health',
    description: 'Check oracle-v2 HTTP API health at port 47778',
    category: 'runtime',
    mutating: false,
  },
  {
    id: 'fleet-panes',
    label: 'Fleet layout',
    description: 'Show all tmux sessions and pane structure',
    category: 'process',
    mutating: false,
  },
]

const COMMAND_EXECUTIONS: Record<CommandId, (repoRoot: string) => CommandExecutionSpec> = {
  'git-status': (repoRoot) => ({
    executable: 'git',
    args: ['status', '--short', '--branch'],
    cwd: repoRoot,
    timeoutMs: 5000,
  }),
  'git-branch': (repoRoot) => ({
    executable: 'git',
    args: ['branch', '--show-current'],
    cwd: repoRoot,
    timeoutMs: 5000,
  }),
  'git-log': (repoRoot) => ({
    executable: 'git',
    args: ['log', '-1', '--stat', '--oneline'],
    cwd: repoRoot,
    timeoutMs: 5000,
  }),
  'tmux-ls': () => ({
    executable: 'tmux',
    args: ['ls'],
    timeoutMs: 5000,
  }),
  'node-version': () => ({
    executable: 'node',
    args: ['--version'],
    timeoutMs: 3000,
  }),
  'bun-version': () => ({
    executable: 'bun',
    args: ['--version'],
    timeoutMs: 3000,
  }),
  'python-version': () => ({
    executable: 'python3',
    args: ['--version'],
    timeoutMs: 3000,
  }),
  'tmux-fleet': () => ({
    executable: 'tmux',
    args: ['list-panes', '-t', 'tham-oracle-stack:fleet-ops', '-F', 'pane #{pane_index}: #{pane_title} [#{pane_width}x#{pane_height}] pid=#{pane_pid}'],
    timeoutMs: 5000,
  }),
  '9router-models': () => ({
    executable: 'curl',
    args: ['-s', '--max-time', '5', 'http://172.21.112.1:20128/v1/models'],
    timeoutMs: 8000,
  }),
  'oracle-v2-health': () => ({
    executable: 'curl',
    args: ['-s', '--max-time', '3', 'http://localhost:47778/api/stats'],
    timeoutMs: 5000,
  }),
  'fleet-panes': () => ({
    executable: 'tmux',
    args: ['list-panes', '-a', '-F', '#S:#W.#{pane_index} [#{pane_title}] #{pane_current_command}'],
    timeoutMs: 5000,
  }),
}

export function getCommandExecution(commandId: CommandId, repoRoot: string): CommandExecutionSpec | null {
  const builder = COMMAND_EXECUTIONS[commandId]
  return builder ? builder(repoRoot) : null
}

export function isCommandId(value: string): value is CommandId {
  return Object.prototype.hasOwnProperty.call(COMMAND_EXECUTIONS, value)
}
