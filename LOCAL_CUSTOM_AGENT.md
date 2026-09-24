# Local Custom Agent for Branch QA, Review, Merge Safety, and Deploy

This repository now includes a reusable local tool:

- `/home/runner/work/naimbouallagui/naimbouallagui/scripts/custom-qa-agent.sh`

It helps you automate:

1. tests and lint on your current branch
2. modern code review checks (static/security/type checks)
3. merge conflict detection against a target branch
4. regression checks after a simulated merge
5. optional deploy after all checks pass

## Quick setup (works in any project)

1. Copy these files into your project:
   - `scripts/custom-qa-agent.sh`
   - `.qa-agent.conf.example`
2. Create config:
   - `cp .qa-agent.conf.example .qa-agent.conf`
3. Edit `.qa-agent.conf` with your real commands.
4. Make script executable:
   - `chmod +x scripts/custom-qa-agent.sh`

## Run locally

From your project root:

```bash
./scripts/custom-qa-agent.sh main
```

With deploy:

```bash
./scripts/custom-qa-agent.sh main --deploy
```

## Notes

- The script uses `git worktree` and a temporary folder in `/tmp` to simulate merge checks safely.
- It exits immediately on failure, so deploy runs only when all quality gates pass.
- You can integrate it with any stack (Node, Python, Java, Go, etc.) by changing commands in `.qa-agent.conf`.
