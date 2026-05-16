import path from 'path'
import os from 'os'

// Absolute path — never relative to process.cwd() which changes based on launch dir
export const REPO_ROOT = process.env.THAM_REPO_ROOT ||
  path.join(os.homedir(), 'ghq/github.com/E0993599799/tham-oracle')

export const PSI = path.join(REPO_ROOT, 'ψ')

export const EXEC_OPTS = {
  encoding: 'utf8' as const,
  timeout: 8000,
  cwd: REPO_ROOT,
}
