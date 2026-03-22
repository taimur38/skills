#!/bin/bash
# Install taimur-skills: symlinks scripts into ~/bin and skills into ~/.claude/skills
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/bin"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$BIN_DIR" "$SKILLS_DIR"

# Symlink each skill directory into ~/.claude/skills
for skill_dir in "$REPO_DIR"/md2*/; do
  skill_name="$(basename "$skill_dir")"
  target="$SKILLS_DIR/$skill_name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "  skip $skill_name skill (already exists)"
  else
    ln -s "$skill_dir" "$target"
    echo "  linked skill: $skill_name"
  fi
done

# Symlink each script into ~/bin
for skill_dir in "$REPO_DIR"/md2*/; do
  skill_name="$(basename "$skill_dir")"
  script="$skill_dir/scripts/$skill_name"
  if [ -f "$script" ]; then
    chmod +x "$script"
    target="$BIN_DIR/$skill_name"
    if [ -L "$target" ] || [ -e "$target" ]; then
      echo "  skip $skill_name script (already exists)"
    else
      ln -s "$script" "$target"
      echo "  linked script: $skill_name → ~/bin/"
    fi
  fi
done

echo "Done. Make sure ~/bin is in your PATH."
