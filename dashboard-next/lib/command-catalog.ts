export type CommandId =
  | 'git-status'
  | 'git-branch'
  | 'git-log'
  | 'tmux-ls'
  | 'node-version'
  | 'bun-version'
  | 'python-version'

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
}

export function getCommandExecution(commandId: CommandId, repoRoot: string): CommandExecutionSpec | null {
  const builder = COMMAND_EXECUTIONS[commandId]
  return builder ? builder(repoRoot) : null
}

export function isCommandId(value: string): value is CommandId {
  return Object.prototype.hasOwnProperty.call(COMMAND_EXECUTIONS, value)
}
