# Claude Code Plugins on Mac

## 1. Prerequisites

```bash
curl -fsSL https://claude.ai/install.sh | bash
brew install node uv gh
gh auth login
```

Open a new terminal after this.

## 2. Add marketplaces

```bash
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add wshobson/agents
claude plugin marketplace add juliusbrussee/caveman
claude plugin marketplace add MemPalace/mempalace
claude plugin marketplace add affaan-m/ecc
claude plugin marketplace add forrestchang/andrej-karpathy-skills
```

## 3. Install plugins

```bash
claude plugin install code-review@claude-plugins-official
claude plugin install code-simplifier@claude-plugins-official
claude plugin install claude-code-setup@claude-plugins-official
claude plugin install superpowers@claude-plugins-official
claude plugin install codebase-cleanup@claude-code-workflows
claude plugin install code-refactoring@claude-code-workflows
claude plugin install caveman@caveman
claude plugin install ecc@ecc
claude plugin install andrej-karpathy-skills@karpathy-skills
```

MemPalace:

```bash
uv tool install mempalace
claude plugin install mempalace@mempalace
mempalace init ~/path/to/your/project
```

## 4. RTK

```bash
brew install rtk
rtk init -g
```

## 5. read-once

```bash
curl -fsSL https://raw.githubusercontent.com/Bande-a-Bonnot/Boucle-framework/main/tools/read-once/install.sh | bash
```

## 6. Check

Restart Claude Code, then:

```bash
claude plugin list
rtk gain
```

## Usage

| Plugin                                                                | Command                                                       |
| --------------------------------------------------------------------- | ------------------------------------------------------------- |
| caveman, rtk, read-once, mempalace, superpowers, karpathy-skills, ecc | Automatic                                                     |
| code-review                                                           | `/code-review:code-review`                                    |
| codebase-cleanup                                                      | `/codebase-cleanup:tech-debt`, `/codebase-cleanup:deps-audit` |
| code-refactoring                                                      | `/code-refactoring:refactor-clean`                            |
| code-simplifier                                                       | Ask: "simplify the code I just changed"                       |
| claude-code-setup                                                     | `/claude-code-setup:claude-automation-recommender`            |
| superpowers (manual)                                                  | `/superpowers:brainstorming <idea>`                           |
