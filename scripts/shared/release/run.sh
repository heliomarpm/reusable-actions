#!/usr/bin/env bash
set -Eeuo pipefail

# ─────────────────────────────────────────────────────────────
# Actions Release - Zero-Dependency Git Tag & Release Engine
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

log "🚀 Release Engine - Initializing"

# ─────────────────────────────────────────────────────────────
# Inputs & Configuration
# ─────────────────────────────────────────────────────────────
PROJECT_PATH="${PROJECT_PATH:-.}"
INPUT_BRANCH="${INPUT_BRANCH:-}"
RELEASE_BRANCHES="${RELEASE_BRANCHES:-main,master}"
DEVELOP_BRANCHES="${DEVELOP_BRANCHES:-develop,dev}"
PRERELEASE_BRANCHES="${PRERELEASE_BRANCHES:-release-*,release/*}"
PRERELEASE_INCREMENTAL="${PRERELEASE_INCREMENTAL:-true}"
if [[ -n "${PRERELEASE_STRATEGY:-}" && "$PRERELEASE_STRATEGY" == "same-tag" ]]; then
  PRERELEASE_INCREMENTAL="false"
fi
PRERELEASE_SUFFIX="${PRERELEASE_SUFFIX:-rc}"
INPUT_VERSION="${INPUT_VERSION:-}"
VERSION_FORMAT="${VERSION_FORMAT:-}"
INPUT_RELEASE_NOTES="${INPUT_RELEASE_NOTES:-}"
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

# Se não estiver em branch de release ou prerelease e nenhuma versão explícita foi fornecida (ou for Unreleased), não cria release
if [[ "$MODE" != "release" && "$MODE" != "prerelease" && ( -z "$INPUT_VERSION" || "$INPUT_VERSION" == "Unreleased" ) ]]; then
  log "ℹ️ Branch '$CURRENT_BRANCH' is not a release/prerelease branch ($RELEASE_BRANCHES, $PRERELEASE_BRANCHES). Skipping release creation."
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "version=" >> "$GITHUB_OUTPUT"
    echo "tag=" >> "$GITHUB_OUTPUT"
    echo "has_changes=false" >> "$GITHUB_OUTPUT"
    echo "release_notes=" >> "$GITHUB_OUTPUT"
  fi
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    append_template_to_summary "summary-release-develop.md" \
      CURRENT_BRANCH "$CURRENT_BRANCH" \
      RELEASE_BRANCHES "$RELEASE_BRANCHES" \
      MODE "$MODE"
  fi
  exit 0
fi

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

# ─────────────────────────────────────────────────────────────
# Resolução de Versão e Notas de Release
# Prioridade 1: INPUT_VERSION e INPUT_RELEASE_NOTES (repassados pelo changelog)
# Prioridade 2: Cálculo autônomo baseado no histórico Git
# ─────────────────────────────────────────────────────────────
HAS_BREAKING=false
HAS_FEAT=false
HAS_FIX=false
TOTAL_COMMITS=0

if [[ -n "$INPUT_VERSION" && "$INPUT_VERSION" != "Unreleased" ]]; then
  log "💡 Using provided version from input/changelog: $INPUT_VERSION"
  RESOLVED_VERSION="$INPUT_VERSION"
  RESOLVED_TAG="$RESOLVED_VERSION"
  HAS_CHANGES=true

  if [[ -n "$INPUT_RELEASE_NOTES" ]]; then
    echo "$INPUT_RELEASE_NOTES" > "$NOTES_FILE"
  fi
else
  # Determina range de commits
  resolve_commit_range "$MODE" "$LAST_TAG" "$LAST_STABLE_TAG" "$LAST_RELEASE_COMMIT" false
  log "🔍 Commit range: $RANGE ($SINCE_LABEL)"

  parse_conventional_commits "$RANGE" "$REPO_URL" "$TEMP_DIR"
  if [[ -f "$TEMP_DIR/stats.env" ]]; then
    # shellcheck source=/dev/null
    source "$TEMP_DIR/stats.env"
  fi

  log "📊 Analyzed $TOTAL_COMMITS relevant commits (Breaking: $HAS_BREAKING, Feat: $HAS_FEAT, Fix: $HAS_FIX)"

  build_release_notes_md "$TEMP_DIR" "$NOTES_FILE"

  HAS_CHANGES=false
  if [[ -s "$NOTES_FILE" ]]; then
    HAS_CHANGES=true
  fi

  HAS_BUMP=false
  if [[ "$HAS_BREAKING" == "true" || "$HAS_FEAT" == "true" || "$HAS_FIX" == "true" ]]; then
    HAS_BUMP=true
  fi

  PRERELEASE_PROMOTION=false
  if [[ "$MODE" == "release" && -n "$LAST_TAG" && "$LAST_TAG" =~ - ]]; then
    PRERELEASE_PROMOTION=true
  fi

  # Se não há mudanças com impacto SemVer identificadas
  if [[ "$HAS_BUMP" == "false" && "$PRERELEASE_PROMOTION" == "false" ]]; then
    log "ℹ️ No SemVer-impacting changes detected since last release ($LAST_TAG). No new release needed."
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      echo "version=" >> "$GITHUB_OUTPUT"
      echo "tag=" >> "$GITHUB_OUTPUT"
      echo "has_changes=false" >> "$GITHUB_OUTPUT"
      echo "release_notes=" >> "$GITHUB_OUTPUT"
    fi
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
      LAST_TAG_URL=""
      if [[ -n "$REPO_URL" && -n "$LAST_TAG" ]]; then
        LAST_TAG_URL="${REPO_URL}/releases/tag/${LAST_TAG}"
      fi

      LAST_VERSION_CELL="_(Nenhuma tag anterior encontrada)_"
      if [[ -n "$LAST_TAG_URL" ]]; then
        LAST_VERSION_CELL="[**\`$LAST_TAG\`**]($LAST_TAG_URL)"
      elif [[ -n "$LAST_TAG" ]]; then
        LAST_VERSION_CELL="\`$LAST_TAG\`"
      fi

      EXTRA_METADATA="| **Commits Analisados** | $TOTAL_COMMITS |"
      EXPLANATION=$(cat <<EOF
Não foram identificados novos commits com impacto para gerar um release desde a tag \`${LAST_TAG:-inicial}\`.
> 👉 Para gerar uma nova release, envie commits convencionais como \`feat:\` (minor) ou \`fix:\` (patch).
EOF
)

      append_template_to_summary "summary-release-skipped.md" \
        LAST_VERSION "$LAST_VERSION_CELL" \
        CURRENT_BRANCH "$CURRENT_BRANCH" \
        EXTRA_METADATA "$EXTRA_METADATA" \
        REASON "Nenhuma alteração com impacto de versão encontrada desde $SINCE_LABEL." \
        EXPLANATION "$EXPLANATION" \
        LAST_TAG "${LAST_TAG:-inicial}"
    fi
    exit 0
  fi

  # Branch target semver
  BRANCH_TARGET_SEMVER=""
  if [[ "$CURRENT_BRANCH" =~ ^release[-/][vV]?([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
    BRANCH_TARGET_SEMVER="${BASH_REMATCH[1]}"
    if [[ "$BRANCH_TARGET_SEMVER" =~ ^[0-9]+\.[0-9]+$ ]]; then
      BRANCH_TARGET_SEMVER="${BRANCH_TARGET_SEMVER}.0"
    fi
  fi

  # Pre-release promotion target
  PRERELEASE_TARGET_SEMVER=""
  if [[ "$MODE" == "release" && -n "$LAST_TAG" && "$LAST_TAG" =~ - ]]; then
    CLEAN_FROM_TAG="${LAST_TAG#v}"
    CLEAN_FROM_TAG="${CLEAN_FROM_TAG%%-*}"
    if [[ "$CLEAN_FROM_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      PRERELEASE_TARGET_SEMVER="$CLEAN_FROM_TAG"
    fi
  fi

  BASE_SEMVER="0.0.0"
  if [[ -n "${LAST_STABLE_TAG:-}" ]]; then
    BASE_SEMVER="${LAST_STABLE_TAG#v}"
  elif [[ -n "$LAST_TAG" ]]; then
    BASE_SEMVER="${LAST_TAG#v}"
  fi

  RESOLVED_VERSION="$(calculate_semver_version "$MODE" "$BASE_SEMVER" "$HAS_BREAKING" "$HAS_FEAT" "$HAS_FIX" "${VERSION_FORMAT:-}" "$PRERELEASE_INCREMENTAL" "$PRERELEASE_SUFFIX" "$BRANCH_TARGET_SEMVER" "$PRERELEASE_TARGET_SEMVER" "")"
  RESOLVED_TAG="$RESOLVED_VERSION"
fi

log "🏷️ Release Target: $RESOLVED_VERSION (Tag: $RESOLVED_TAG)"

# ─────────────────────────────────────────────────────────────
# Criação da Git Tag e GitHub Release
# ─────────────────────────────────────────────────────────────
if git rev-parse "$RESOLVED_TAG" >/dev/null 2>&1; then
  log "⚠️ Tag '$RESOLVED_TAG' already exists in local git. Overwriting tag on current commit..."
  git tag -d "$RESOLVED_TAG" || true
fi

log "🏷️ Creating git tag: $RESOLVED_TAG"
git config user.name "${GIT_USER_NAME:-github-actions[bot]}"
git config user.email "${GIT_USER_EMAIL:-github-actions[bot]@users.noreply.github.com}"
git tag -a "$RESOLVED_TAG" -m "Release $RESOLVED_TAG"

if git remote get-url origin >/dev/null 2>&1; then
  log "📤 Pushing tag '$RESOLVED_TAG' to origin"
  git push origin "$RESOLVED_TAG" --force 2>/dev/null || git push origin "$RESOLVED_TAG" || log "⚠️ Failed to push tag (check permissions)"
else
  log "ℹ️ Skipping git push tag (no 'origin' remote configured)"
fi

IS_PROMOTED=false
if command -v gh >/dev/null 2>&1 && [[ -n "$GITHUB_TOKEN" ]]; then
  IS_EXISTING_RELEASE=false
  if GH_TOKEN="$GITHUB_TOKEN" gh release view "$RESOLVED_TAG" >/dev/null 2>&1; then
    IS_EXISTING_RELEASE=true
  fi

  if [[ "$MODE" == "prerelease" ]]; then
    if [[ "$IS_EXISTING_RELEASE" == "true" ]]; then
      log "🔄 Updating existing GitHub Pre-Release: $RESOLVED_TAG"
      GH_TOKEN="$GITHUB_TOKEN" gh release edit "$RESOLVED_TAG" \
        --title "$RESOLVED_TAG" \
        --notes-file "$NOTES_FILE" \
        --prerelease || log "⚠️ Failed to edit GitHub Pre-Release via gh CLI"
    else
      log "🚀 Creating GitHub Pre-Release: $RESOLVED_TAG"
      GH_TOKEN="$GITHUB_TOKEN" gh release create "$RESOLVED_TAG" \
        --title "$RESOLVED_TAG" \
        --notes-file "$NOTES_FILE" \
        --prerelease || log "⚠️ Failed to create GitHub Pre-Release via gh CLI"
    fi
  elif [[ "$MODE" == "release" ]]; then
    if [[ "$IS_EXISTING_RELEASE" == "true" ]]; then
      log "🚀 Promoting existing Pre-Release '$RESOLVED_TAG' to Latest Release"
      GH_TOKEN="$GITHUB_TOKEN" gh release edit "$RESOLVED_TAG" \
        --title "$RESOLVED_TAG" \
        --notes-file "$NOTES_FILE" \
        --prerelease=false \
        --latest || log "⚠️ Failed to promote GitHub Release via gh CLI"
      IS_PROMOTED=true
    else
      log "🚀 Creating GitHub Release: $RESOLVED_TAG (Latest)"
      GH_TOKEN="$GITHUB_TOKEN" gh release create "$RESOLVED_TAG" \
        --title "$RESOLVED_TAG" \
        --notes-file "$NOTES_FILE" \
        --latest || log "⚠️ Failed to create GitHub Release via gh CLI"
    fi
  else
    log "ℹ️ Skipping GitHub Release creation for mode: $MODE"
  fi
else
  log "ℹ️ Skipping GitHub Release creation (gh CLI not installed or GITHUB_TOKEN empty)"
fi

# ─────────────────────────────────────────────────────────────
# Outputs para o GitHub Actions
# ─────────────────────────────────────────────────────────────
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=$RESOLVED_VERSION" >> "$GITHUB_OUTPUT"
  echo "tag=$RESOLVED_TAG" >> "$GITHUB_OUTPUT"
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
  RELEASE_URL=""
  COMPARE_URL=""
  LAST_TAG_URL=""
  COMMIT_URL=""
  COMMIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo '')"

  if [[ -n "$REPO_URL" ]]; then
    [[ -n "$RESOLVED_TAG" ]] && RELEASE_URL="${REPO_URL}/releases/tag/${RESOLVED_TAG}"
    [[ -n "$LAST_TAG" ]] && LAST_TAG_URL="${REPO_URL}/releases/tag/${LAST_TAG}"
    if [[ -n "$LAST_TAG" && -n "$RESOLVED_TAG" && "$LAST_TAG" != "$RESOLVED_TAG" ]]; then
      COMPARE_URL="${REPO_URL}/compare/${LAST_TAG}...${RESOLVED_TAG}"
    fi
    [[ -n "$COMMIT_SHA" ]] && COMMIT_URL="${REPO_URL}/commit/${COMMIT_SHA}"
  fi

  BUMP_TYPE="patch"
  if [[ "$MODE" == "prerelease" ]]; then
    if [[ "$PRERELEASE_INCREMENTAL" == "true" || "$PRERELEASE_INCREMENTAL" == "rc" ]]; then
      BUMP_TYPE="pre-release ($PRERELEASE_SUFFIX) 🧪"
    else
      BUMP_TYPE="pre-release (same-tag) 🧪"
    fi
  elif [[ "$IS_PROMOTED" == "true" ]]; then
    BUMP_TYPE="promoção para latest 🚀"
  elif [[ "$HAS_BREAKING" == "true" ]]; then
    BUMP_TYPE="major 💥"
  elif [[ "$HAS_FEAT" == "true" ]]; then
    BUMP_TYPE="minor 🚀"
  elif [[ "$HAS_FIX" == "true" ]]; then
    BUMP_TYPE="patch 🐛"
  elif [[ -n "$INPUT_VERSION" ]]; then
    BUMP_TYPE="manual / custom"
  fi

  STATUS_TEXT="🟢 Publicada no GitHub (Latest)"
  if [[ "$MODE" == "prerelease" ]]; then
    STATUS_TEXT="🟡 Pre-Release Publicada no GitHub"
  elif [[ "$IS_PROMOTED" == "true" ]]; then
    STATUS_TEXT="🟢 Publicada no GitHub (Promovida a Latest)"
  fi

  NEW_VERSION_CELL="\`$RESOLVED_TAG\`"
  [[ -n "$RELEASE_URL" ]] && NEW_VERSION_CELL="[**\`$RESOLVED_TAG\`**]($RELEASE_URL)"

  LAST_VERSION_CELL="_(Primeira release)_"
  if [[ -n "$LAST_TAG_URL" ]]; then
    LAST_VERSION_CELL="[**\`$LAST_TAG\`**]($LAST_TAG_URL)"
  elif [[ -n "$LAST_TAG" ]]; then
    LAST_VERSION_CELL="\`$LAST_TAG\`"
  fi

  COMMIT_CELL="\`$COMMIT_SHA\`"
  [[ -n "$COMMIT_URL" ]] && COMMIT_CELL="[\`$COMMIT_SHA\`]($COMMIT_URL)"

  EXTRA_METADATA="| **Commits Analisados** | $TOTAL_COMMITS |"

  QUICK_LINKS=""
  if [[ -n "$RELEASE_URL" || -n "$COMPARE_URL" ]]; then
    LNK_REL=""
    LNK_CMP=""
    [[ -n "$RELEASE_URL" ]] && LNK_REL="- 📦 [Visualizar Release no GitHub]($RELEASE_URL)"
    [[ -n "$COMPARE_URL" ]] && LNK_CMP="- 🔍 [Comparar Alterações com a Release Anterior (\`$LAST_TAG...$RESOLVED_TAG\`)]($COMPARE_URL)"
    QUICK_LINKS=$(cat <<EOF
### 🔗 Links Rápidos
$LNK_REL
$LNK_CMP
EOF
)
  fi

  RELEASE_NOTES=""
  if [[ -s "$NOTES_FILE" ]]; then
    RELEASE_NOTES=$(cat <<EOF
<details open><summary>📋 <strong>Notas da Release (\`$RESOLVED_TAG\`)</strong></summary>

$(cat "$NOTES_FILE")

</details>
EOF
)
  fi

  append_template_to_summary "summary-release-published.md" \
    STATUS "$STATUS_TEXT" \
    NEW_VERSION "$NEW_VERSION_CELL" \
    LAST_VERSION "$LAST_VERSION_CELL" \
    RELEASE_TYPE "$BUMP_TYPE" \
    CURRENT_BRANCH "$CURRENT_BRANCH" \
    COMMIT "$COMMIT_CELL" \
    EXTRA_METADATA "$EXTRA_METADATA" \
    QUICK_LINKS "$QUICK_LINKS" \
    RELEASE_NOTES "$RELEASE_NOTES"
fi

log "🎉 Release Engine completed successfully!"
