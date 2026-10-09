#!/usr/bin/env bash
set -Eeuo pipefail

# ─────────────────────────────────────────────────────────────
# Actions Changelog - Native Zero-Dependency Changelog Engine
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REUSABLE_PATH="${REUSABLE_PATH:-$SCRIPT_DIR/../../..}"

# Carrega helpers compartilhados
if [[ -f "$SCRIPT_DIR/../shell-helpers.sh" ]]; then
  # shellcheck source=scripts/shared/shell-helpers.sh
  source "$SCRIPT_DIR/../shell-helpers.sh"
else
  log() { echo "→ $*" >&2; }
  fail() { echo "::error::$*" >&2; exit 1; }
fi

if [[ -f "$SCRIPT_DIR/../semver-helpers.sh" ]]; then
  # shellcheck source=scripts/shared/semver-helpers.sh
  source "$SCRIPT_DIR/../semver-helpers.sh"
fi

log "🚀 Changelog Action - Initializing"

# ─────────────────────────────────────────────────────────────
# Inputs & Configuration
# ─────────────────────────────────────────────────────────────
ENABLE_CHANGELOG="${ENABLE_CHANGELOG:-true}"
if [[ "$ENABLE_CHANGELOG" != "true" ]]; then
  log "ℹ️ Changelog is disabled (enable-changelog=false). Skipping."
  exit 0
fi

CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"
CHANGELOG_TITLE="${CHANGELOG_TITLE:-"# 📦 Changelog\n\nAll notable changes to this project will be documented in this file."}"
PROJECT_PATH="${PROJECT_PATH:-.}"
INPUT_BRANCH="${INPUT_BRANCH:-}"
RELEASE_BRANCHES="${RELEASE_BRANCHES:-main,master}"
DEVELOP_BRANCHES="${DEVELOP_BRANCHES:-develop,dev}"
PRERELEASE_BRANCHES="${PRERELEASE_BRANCHES:-release-*,release/*}"
INPUT_VERSION="${INPUT_VERSION:-}"
VERSION_FORMAT="${VERSION_FORMAT:-}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

cd "$PROJECT_PATH"

# Validação do repositório Git
if command -v validate_git_repository >/dev/null 2>&1; then
  validate_git_repository
elif ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "❌ O diretório '$(pwd)' não é um repositório Git. Certifique-se de incluir o step 'actions/checkout@v4' com 'fetch-depth: 0' no seu workflow antes de executar esta action!"
fi

# Resolve branch atual
if [[ -n "$INPUT_BRANCH" ]]; then
  CURRENT_BRANCH="$INPUT_BRANCH"
elif [[ -n "${GITHUB_REF_NAME:-}" ]]; then
  CURRENT_BRANCH="$GITHUB_REF_NAME"
else
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
fi
log "📌 Current branch: $CURRENT_BRANCH"

MODE="$(determine_release_mode "$CURRENT_BRANCH" "$RELEASE_BRANCHES" "$PRERELEASE_BRANCHES" "$DEVELOP_BRANCHES")"
log "🎯 Operating mode: $MODE"

# ─────────────────────────────────────────────────────────────
# Setup de Diretório Temporário
# ─────────────────────────────────────────────────────────────
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR:-}"' EXIT
NOTES_FILE="$TEMP_DIR/release_notes.md"
touch "$NOTES_FILE"

REPO_URL="$(get_repo_url)"

LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
LAST_STABLE_TAG="$(git tag -l --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)"
LAST_RELEASE_COMMIT="$(git log -n 1 --grep="^chore(release)" --grep="^chore(changelog)" --format="%H" 2>/dev/null || true)"

# Verifica se o último commit de release é mais recente que a última tag Git
USE_RELEASE_COMMIT=false
if [[ -n "${LAST_RELEASE_COMMIT:-}" && "${LAST_RELEASE_COMMIT:-}" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
  if [[ -z "$LAST_TAG" ]]; then
    USE_RELEASE_COMMIT=true
  elif git log "${LAST_TAG}..HEAD" --format="%H" 2>/dev/null | grep -q "$LAST_RELEASE_COMMIT"; then
    USE_RELEASE_COMMIT=true
  fi
fi

# Determina range de commits
resolve_commit_range "$MODE" "$LAST_TAG" "$LAST_STABLE_TAG" "$LAST_RELEASE_COMMIT" "$USE_RELEASE_COMMIT"
log "🔍 Commit range: $RANGE ($SINCE_LABEL)"

# Extrai e parseia commits convencionais
parse_conventional_commits "$RANGE" "$REPO_URL" "$TEMP_DIR"
if [[ -f "$TEMP_DIR/stats.env" ]]; then
  # shellcheck source=/dev/null
  source "$TEMP_DIR/stats.env"
fi

log "📊 Analyzed $TOTAL_COMMITS relevant commits (Breaking: $HAS_BREAKING, Feat: $HAS_FEAT, Fix: $HAS_FIX)"

build_release_notes_md "$TEMP_DIR" "$NOTES_FILE"

# Verifica se o arquivo CHANGELOG.md existe
if [[ ! -f "$CHANGELOG_FILE" ]]; then
  log "📝 Initializing $CHANGELOG_FILE"
  printf "%b\n\n" "$CHANGELOG_TITLE" > "$CHANGELOG_FILE"
fi

# Checa se o CHANGELOG.md já possui seção [Unreleased] pré-existente
HAS_EXISTING_UNRELEASED=false
if grep -qiE "^## \[Unreleased\]" "$CHANGELOG_FILE"; then
  HAS_EXISTING_UNRELEASED=true
fi

# Extrai conteúdo de [Unreleased] pré-existente se houver
EXISTING_UNRELEASED_CONTENT="$TEMP_DIR/existing_unreleased.txt"
if [[ "$HAS_EXISTING_UNRELEASED" == "true" ]]; then
  awk '
    BEGIN { capture=0 }
    /^## \[Unreleased\]/ { capture=1; next }
    /^## \[/ { if (capture) exit }
    capture { print }
  ' "$CHANGELOG_FILE" | convert_emojis > "$EXISTING_UNRELEASED_CONTENT"
fi

HAS_CHANGES=false
if [[ -s "$NOTES_FILE" ]]; then
  HAS_CHANGES=true
elif [[ -s "$EXISTING_UNRELEASED_CONTENT" ]]; then
  HAS_CHANGES=true
  cat "$EXISTING_UNRELEASED_CONTENT" > "$NOTES_FILE"
fi

# Se não há absolutamente nenhuma alteração
if [[ "$HAS_CHANGES" == "false" ]]; then
  log "ℹ️ No changes detected. Changelog is up to date."
  echo "version=" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "tag=" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "has_changes=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "release_notes=" >> "${GITHUB_OUTPUT:-/dev/null}"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    append_template_to_summary "summary-changelog-skipped.md" \
      CHANGELOG_FILE "$CHANGELOG_FILE" \
      CURRENT_BRANCH "$CURRENT_BRANCH" \
      MODE "$MODE" \
      COMMITS_COUNT "$TOTAL_COMMITS" \
      SINCE_LABEL "$SINCE_LABEL"
  fi
  exit 0
fi

# ─────────────────────────────────────────────────────────────
# Resolução de Versão
# Changelog NUNCA calcula versão sozinho:
# - Se INPUT_VERSION foi fornecida (ex: via release): promove para a versão informada.
# - Se INPUT_VERSION NÃO foi fornecida: sempre registra sob [Unreleased].
# ─────────────────────────────────────────────────────────────
RESOLVED_VERSION=""
TODAY="$(date +"%Y-%m-%d")"

if [[ -n "$INPUT_VERSION" && "$INPUT_VERSION" != "Unreleased" ]]; then
  RESOLVED_VERSION="$INPUT_VERSION"
  if [[ "$RESOLVED_VERSION" =~ [0-9]{4}[.-][0-9]{2} ]]; then
    SECTION_HEADER="## [${RESOLVED_VERSION}]"
  else
    SECTION_HEADER="## [${RESOLVED_VERSION}] - ${TODAY}"
  fi
else
  RESOLVED_VERSION="Unreleased"
  SECTION_HEADER="## [Unreleased]"
fi

log "🏷️ Target Version: $RESOLVED_VERSION (Header: $SECTION_HEADER)"

# ─────────────────────────────────────────────────────────────
# Atualização Atômica do CHANGELOG.md
# Substitui [Unreleased] existente ou insere no topo
# ─────────────────────────────────────────────────────────────
NEW_SECTION_FILE="$TEMP_DIR/new_section.md"
{
  echo "$SECTION_HEADER"
  echo ""
  if [[ -s "$NOTES_FILE" ]]; then
    cat "$NOTES_FILE"
    echo ""
  fi
} > "$NEW_SECTION_FILE"

UPDATED_CHANGELOG="$TEMP_DIR/CHANGELOG.updated.md"

# Atualização do arquivo CHANGELOG.md via Python 3 (com fallback em awk)
python3 -c '
import sys, re

target_path = sys.argv[1]
new_sec_path = sys.argv[2]

with open(target_path, "r", encoding="utf-8") as f:
    content = f.read()

with open(new_sec_path, "r", encoding="utf-8") as f:
    new_sec = f.read().strip()

if re.search(r"^##\s+\[Unreleased\]", content, flags=re.MULTILINE):
    pattern = r"##\s+\[Unreleased\].*?(?=(?:\n##\s+\[\S+\]|\Z))"
    replacement = new_sec + "\n"
    updated = re.sub(pattern, replacement, content, count=1, flags=re.DOTALL)
    with open(target_path, "w", encoding="utf-8") as f:
        f.write(updated.strip() + "\n")
else:
    match = re.search(r"^##\s+\[", content, flags=re.MULTILINE)
    if match:
        header = content[:match.start()].rstrip()
        rest = content[match.start():].lstrip("\n")
        result = header + "\n\n" + new_sec + "\n\n" + rest.strip() + "\n"
        with open(target_path, "w", encoding="utf-8") as f:
            f.write(result)
    else:
        result = content.rstrip() + "\n\n" + new_sec + "\n"
        with open(target_path, "w", encoding="utf-8") as f:
            f.write(result)
' "$CHANGELOG_FILE" "$NEW_SECTION_FILE" 2>/dev/null || awk -v new_sec_file="$NEW_SECTION_FILE" '
  BEGIN {
    inserted = 0
    skipping_unreleased = 0
  }

  /^## \[Unreleased\]/ {
    while ((getline line < new_sec_file) > 0) {
      print line
    }
    close(new_sec_file)
    inserted = 1
    skipping_unreleased = 1
    next
  }

  /^## \[/ {
    if (skipping_unreleased) {
      skipping_unreleased = 0
    }
    if (!inserted) {
      while ((getline line < new_sec_file) > 0) {
        print line
      }
      close(new_sec_file)
      inserted = 1
      print ""
    }
    print $0
    next
  }

  {
    if (!skipping_unreleased) {
      print $0
    }
  }

  END {
    if (!inserted) {
      print ""
      while ((getline line < new_sec_file) > 0) {
        print line
      }
      close(new_sec_file)
    }
  }
' "$CHANGELOG_FILE" > "$UPDATED_CHANGELOG" && cp "$UPDATED_CHANGELOG" "$CHANGELOG_FILE" 2>/dev/null || true
log "✅ $CHANGELOG_FILE updated successfully"

# ─────────────────────────────────────────────────────────────
# Commit & Push do CHANGELOG.md
# ─────────────────────────────────────────────────────────────
git config user.name "${GIT_USER_NAME:-github-actions[bot]}"
git config user.email "${GIT_USER_EMAIL:-github-actions[bot]@users.noreply.github.com}"

if [[ -n "$COMMIT_MESSAGE" ]]; then
  MSG="$COMMIT_MESSAGE"
elif [[ "$RESOLVED_VERSION" != "Unreleased" ]]; then
  MSG="chore(release): ${RESOLVED_VERSION} [skip ci]"
else
  MSG="chore(changelog): update [Unreleased] in CHANGELOG.md [skip ci]"
fi

git add "$CHANGELOG_FILE"
if ! git diff --cached --quiet; then
  log "💾 Committing $CHANGELOG_FILE with message: '$MSG'"
  git commit -m "$MSG"
  if git remote get-url origin >/dev/null 2>&1; then
    git push origin "$CURRENT_BRANCH" || log "⚠️ Failed to push changelog commit"
  else
    log "ℹ️ Skipping git push commit (no 'origin' remote configured)"
  fi
else
  log "ℹ️ No git changes to commit"
fi

# ─────────────────────────────────────────────────────────────
# Outputs para o GitHub Actions
# ─────────────────────────────────────────────────────────────
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=$RESOLVED_VERSION" >> "$GITHUB_OUTPUT"
  echo "has_changes=$HAS_CHANGES" >> "$GITHUB_OUTPUT"
  {
    echo "release_notes<<EOF"
    cat "$NOTES_FILE"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi

# ─────────────────────────────────────────────────────────────
# Job Summary para o GitHub Actions
# ─────────────────────────────────────────────────────────────
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  CHANGELOG_NOTES=""
  if [[ -s "$NOTES_FILE" ]]; then
    CHANGELOG_NOTES=$(cat <<EOF
<details open><summary>📋 <strong>Visualizar Alterações Registradas (\`$RESOLVED_VERSION\`)</strong></summary>

$(cat "$NOTES_FILE")

</details>
EOF
)
  fi

  append_template_to_summary "summary-changelog.md" \
    CHANGELOG_FILE "$CHANGELOG_FILE" \
    VERSION "$RESOLVED_VERSION" \
    MODE "$MODE" \
    CURRENT_BRANCH "$CURRENT_BRANCH" \
    COMMITS_COUNT "$TOTAL_COMMITS" \
    CHANGELOG_NOTES "$CHANGELOG_NOTES"
fi

log "🎉 Changelog Action completed successfully!"
