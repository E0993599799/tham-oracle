"""Compatibility wrapper for the canonical executor_lane_router module.

This file keeps the documented hyphenated entrypoint working while the
implementation lives in `executor_lane_router.py`.
"""

from executor_lane_router import main


if __name__ == "__main__":
    main()
