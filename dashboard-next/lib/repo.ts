import path from 'path'

// Absolute path — prefer THAM_REPO_ROOT, fallback to current working directory parent if in dashboard-next
export const REPO_ROOT = process.env.THAM_REPO_ROOT ||
  (process.cwd().endsWith('dashboard-next') ? path.join(process.cwd(), '..') : process.cwd())

export const PSI = path.join(REPO_ROOT, 'ψ')

export const EXEC_OPTS = {
  encoding: 'utf8' as const,
  timeout: 8000,
  cwd: REPO_ROOT,
}
