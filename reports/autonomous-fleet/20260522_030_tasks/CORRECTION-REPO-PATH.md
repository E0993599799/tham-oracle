IMPORTANT CORRECTION — WRONG WORKING DIRECTORY RISK

Stop any current work immediately if it is running from `D:\01 Main Work\Boots\Agentic AI\mission-control` or `/mnt/d/01 Main Work/Boots/Agentic AI/mission-control`.

The correct repo is the nested repo:

Windows path:
`D:\01 Main Work\Boots\Agentic AI\mission-control\tham-oracle`

WSL path:
`/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle`

Before doing anything else, verify and report:
1. `pwd`
2. `git rev-parse --show-toplevel`
3. `git remote -v`

Expected git root:
`/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle`

Expected remote:
`https://github.com/E0993599799/tham-oracle.git`

Do not deploy, edit, or continue unless the git root is exactly `tham-oracle` above. If you already inspected or changed the parent `mission-control` folder, report that as a risk/blocker and do not continue until corrected.

Then continue your assigned mission only inside the correct `tham-oracle` repo. Keep all prior constraints: no commit, push, merge, delete, git reset, git clean, force-push, or secret exposure. Vercel deploy remains approved only for Dheva after correct repo verification and proof.
