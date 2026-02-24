---
description: Create git worktree and work from it
---

## Context

You are now working in a GIT WORKTREE session. This is a critical context that affects ALL your operations.

**Current git status:**
!`git rev-parse --is-inside-work-tree 2>/dev/null && echo "Git repo: YES" || echo "Git repo: NO"`

**Main repository root:**
!`git rev-parse --show-toplevel 2>/dev/null || echo "Not in a git repository"`

**Existing worktrees:**
!`git worktree list 2>/dev/null || echo "No worktrees or not a git repo"`

## Task

Create a new git worktree for: **$ARGUMENTS**

### Instructions

1. **Validate** we are in a git repository. If not, stop and inform the user.

2. **Parse the arguments**:
   - If `$1` looks like a branch name only (e.g., `feature/my-feature`), create worktree at `../<repo-name>-$1` 
   - If `$2` is provided, use `$1` as path and `$2` as branch
   - Default worktree location: sibling directory to the main repo

3. **Create the worktree**:
   ```bash
   git worktree add <path> <branch>
   # or for new branch:
   git worktree add -b <new-branch> <path>
   ```

4. **CRITICAL - After creating the worktree**:
   - Report the absolute path of the new worktree
   - ALL subsequent file operations MUST use the worktree path as base
   - When running commands, use `workdir` parameter pointing to the worktree

5. **Worktree awareness rules** (apply to ALL future operations in this session):
   - Always prefix file paths with the worktree absolute path
   - When using bash commands, set `workdir` to the worktree path
   - Never accidentally modify files in the main repository
   - Use `git worktree list` to verify worktree status when needed
   - Remember: commits in the worktree are shared with the main repo
   - To remove worktree later: `git worktree remove <path>`

6. **Confirm success** by:
   - Showing `git worktree list` output
   - Displaying the current branch in the new worktree
   - Stating the absolute path that will be used for all operations

## Session Memory

After setup, remember these for the entire session:
- **WORKTREE_PATH**: The absolute path to the worktree
- **WORKTREE_BRANCH**: The branch checked out in the worktree  
- **MAIN_REPO_PATH**: The path to the main repository (do not modify)

All file reads, writes, and bash commands should default to WORKTREE_PATH.
