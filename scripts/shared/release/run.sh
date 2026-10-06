#!/usr/bin/env bash
set -Eeuo pipefail

# ─────────────────────────────────────────────────────────────
# Actions Release - Zero-Dependency Git Tag & Release Engine
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REUSABLE_PATH="${REUSABLE_PATH:-$SCRIPT_DIR/../../..}"

# Carrega helpers se existirem
if [[ -f "$SCRIPT_DIR/../shell-helpers.sh" ]]; then
  source "$SCRIPT_DIR/../shell-helpers.sh"
else
  log() { echo "→ $*" >&2; }
  fail() { echo "::error::$*" >&2; exit 1; }
fi

# ─────────────────────────────────────────────────────────────
# Emoji Shortcode Converter (e.g. :gear: -> ⚙️)
# ─────────────────────────────────────────────────────────────
convert_emojis() {
  local cmd=(
    sed
    -e 's/:art:/🎨/g'
    -e 's/:zap:/⚡/g'
    -e 's/:fire:/🔥/g'
    -e 's/:bug:/🐛/g'
    -e 's/:ambulance:/🚑/g'
    -e 's/:sparkles:/✨/g'
    -e 's/:memo:/📝/g'
    -e 's/:rocket:/🚀/g'
    -e 's/:lipstick:/💄/g'
    -e 's/:tada:/🎉/g'
    -e 's/:white_check_mark:/✅/g'
    -e 's/:lock:/🔒/g'
    -e 's/:bookmark:/🔖/g'
    -e 's/:rotating_light:/🚨/g'
    -e 's/:construction:/🚧/g'
    -e 's/:green_heart:/💚/g'
    -e 's/:arrow_down:/⬇️/g'
    -e 's/:arrow_up:/⬆️/g'
    -e 's/:pushpin:/📌/g'
    -e 's/:construction_worker:/👷/g'
    -e 's/:chart_with_upwards_trend:/📈/g'
    -e 's/:recycle:/♻️/g'
    -e 's/:heavy_plus_sign:/➕/g'
    -e 's/:heavy_minus_sign:/➖/g'
    -e 's/:wrench:/🔧/g'
    -e 's/:hammer:/🔨/g'
    -e 's/:globe_with_meridians:/🌐/g'
    -e 's/:pencil2:/✏️/g'
    -e 's/:poop:/💩/g'
    -e 's/:rewind:/⏪/g'
    -e 's/:twisted_rightwards_arrows:/🔀/g'
    -e 's/:package:/📦/g'
    -e 's/:alien:/👽/g'
    -e 's/:truck:/🚚/g'
    -e 's/:page_facing_up:/📄/g'
    -e 's/:boom:/💥/g'
    -e 's/:bento:/🍱/g'
    -e 's/:wheelchair:/♿/g'
    -e 's/:bulb:/💡/g'
    -e 's/:beers:/🍻/g'
    -e 's/:speech_balloon:/💬/g'
    -e 's/:card_file_box:/🗃️/g'
    -e 's/:loud_sound:/🔊/g'
    -e 's/:mute:/🔇/g'
    -e 's/:busts_in_silhouette:/👥/g'
    -e 's/:children_crossing:/🚸/g'
    -e 's/:building_construction:/🏗️/g'
    -e 's/:iphone:/📱/g'
    -e 's/:clown_face:/🤡/g'
    -e 's/:egg:/🥚/g'
    -e 's/:see_no_evil:/🙈/g'
    -e 's/:camera_flash:/📸/g'
    -e 's/:alembic:/⚗️/g'
    -e 's/:mag:/🔍/g'
    -e 's/:label:/🏷️/g'
    -e 's/:seedling:/🌱/g'
    -e 's/:triangular_flag_on_post:/🚩/g'
    -e 's/:goal_net:/🥅/g'
    -e 's/:dizzy:/💫/g'
    -e 's/:wastebasket:/🗑️/g'
    -e 's/:passport_control:/🛂/g'
    -e 's/:adhesive_bandage:/🩹/g'
    -e 's/:monocle_face:/🧐/g'
    -e 's/:coffin:/⚰️/g'
    -e 's/:test_tube:/🧪/g'
    -e 's/:necktie:/👔/g'
    -e 's/:stethoscope:/🩺/g'
    -e 's/:bricks:/🧱/g'
    -e 's/:technologist:/🧑💻/g'
    -e 's/:gear:/⚙️/g'
  )

  if [[ $# -gt 0 ]]; then
    echo "$1" | "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

log "🚀 Release Engine - Initializing"

# ─────────────────────────────────────────────────────────────
# Inputs & Configuration
# ─────────────────────────────────────────────────────────────
PROJECT_PATH="${PROJECT_PATH:-.}"
INPUT_BRANCH="${INPUT_BRANCH:-}"
RELEASE_BRANCHES="${RELEASE_BRANCHES:-main,master}"
DEVELOP_BRANCHES="${DEVELOP_BRANCHES:-develop,dev}"
PRERELEASE_BRANCHES="${PRERELEASE_BRANCHES:-release-*,release/*}"
PRERELEASE_STRATEGY="${PRERELEASE_STRATEGY:-rc}"
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

# Determina o modo de operação via glob pattern matching
matches_pattern_csv() {
  local item="$1"
  local csv="$2"
  local IFS=','
  for entry in $csv; do
    entry="$(echo "$entry" | xargs)" # trim
    # Sem aspas em $entry para permitir glob pattern matching (ex: release-*, release/*)
    if [[ "$item" == $entry ]]; then
      return 0
    fi
  done
  return 1
}

MODE="preview"
if matches_pattern_csv "$CURRENT_BRANCH" "$RELEASE_BRANCHES"; then
  MODE="release"
elif matches_pattern_csv "$CURRENT_BRANCH" "$PRERELEASE_BRANCHES"; then
  MODE="prerelease"
elif matches_pattern_csv "$CURRENT_BRANCH" "$DEVELOP_BRANCHES"; then
  MODE="develop"
fi
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
# Determina o range de commits a inspecionar
# ─────────────────────────────────────────────────────────────
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
LAST_STABLE_TAG="$(git tag -l --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)"
RANGE=""
SINCE_LABEL=""

if [[ "$MODE" == "release" && -n "$LAST_TAG" && "$LAST_TAG" =~ - && -n "$LAST_STABLE_TAG" ]]; then
  # Ao promover de release branch (RC) para release final na main, abrange todos os commits desde a última versão estável
  RANGE="${LAST_STABLE_TAG}..HEAD"
  SINCE_LABEL="última release estável '$LAST_STABLE_TAG'"
elif [[ -n "$LAST_TAG" ]]; then
  RANGE="${LAST_TAG}..HEAD"
  SINCE_LABEL="tag '$LAST_TAG'"
else
  LAST_RELEASE_COMMIT="$(git log -n 1 --grep="^chore(release)" --format="%H" 2>/dev/null || true)"
  if [[ -n "$LAST_RELEASE_COMMIT" && "$LAST_RELEASE_COMMIT" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
    RANGE="${LAST_RELEASE_COMMIT}..HEAD"
    SINCE_LABEL="commit de release '${LAST_RELEASE_COMMIT:0:7}'"
  fi
fi

if [[ -z "$RANGE" ]]; then
  RANGE="HEAD"
  SINCE_LABEL="início do repositório"
fi
log "🔍 Commit range: $RANGE ($SINCE_LABEL)"

# ─────────────────────────────────────────────────────────────
# Extração e Classificação de Conventional Commits
# ─────────────────────────────────────────────────────────────
REPO_URL=""
if [[ -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
  REPO_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
else
  REMOTE_ORIGIN="$(git config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$REMOTE_ORIGIN" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)? ]]; then
    REPO_URL="https://github.com/${BASH_REMATCH[1]}"
  fi
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR:-}"' EXIT

FEAT_FILE="$TEMP_DIR/feat.txt"
FIX_FILE="$TEMP_DIR/fix.txt"
PERF_FILE="$TEMP_DIR/perf.txt"
REFACTOR_FILE="$TEMP_DIR/refactor.txt"
DOCS_FILE="$TEMP_DIR/docs.txt"
TEST_FILE="$TEMP_DIR/test.txt"
CI_FILE="$TEMP_DIR/ci.txt"
CHORE_FILE="$TEMP_DIR/chore.txt"
REVERT_FILE="$TEMP_DIR/revert.txt"
BREAKING_FILE="$TEMP_DIR/breaking.txt"
OTHER_FILE="$TEMP_DIR/other.txt"

touch "$FEAT_FILE" "$FIX_FILE" "$PERF_FILE" "$REFACTOR_FILE" "$DOCS_FILE" \
      "$TEST_FILE" "$CI_FILE" "$CHORE_FILE" "$REVERT_FILE" "$BREAKING_FILE" "$OTHER_FILE"

HAS_BREAKING=false
HAS_FEAT=false
HAS_FIX=false
TOTAL_COMMITS=0

COMMITS_RAW="$(git log "$RANGE" --no-merges --pretty=format:"%H%x1f%h%x1f%s%x1f%b%x1e" -- . 2>/dev/null || true)"

if [[ -n "$COMMITS_RAW" ]]; then
  while IFS=$'\x1f' read -d $'\x1e' -r FULL_HASH SHORT_HASH SUBJECT BODY; do
    FULL_HASH="${FULL_HASH//$'\r'/}"
    FULL_HASH="${FULL_HASH//$'\n'/}"
    FULL_HASH="$(echo "$FULL_HASH" | tr -d '[:space:]')"
    SHORT_HASH="${SHORT_HASH//$'\r'/}"
    SHORT_HASH="${SHORT_HASH//$'\n'/}"
    SHORT_HASH="$(echo "$SHORT_HASH" | tr -d '[:space:]')"
    SUBJECT="${SUBJECT//$'\r'/}"
    SUBJECT="$(echo "$SUBJECT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    [[ -z "$FULL_HASH" ]] && continue

    # Ignora commits automáticos de release, changelog ou skip ci
    if echo "$SUBJECT" | grep -qiE "^chore\((release|changelog)\)|^Merge (pull request|branch)|\[(skip ci|ci skip)\]"; then
      continue
    fi

    TOTAL_COMMITS=$((TOTAL_COMMITS + 1))

    if [[ -n "$REPO_URL" ]]; then
      COMMIT_LINK="([${SHORT_HASH}](${REPO_URL}/commit/${FULL_HASH}))"
    else
      COMMIT_LINK="(${SHORT_HASH})"
    fi

    IS_BREAKING_COMMIT=false
    if echo "$SUBJECT" | grep -qE "^[a-zA-Z]+(\([^\)]+\))?!:"; then
      IS_BREAKING_COMMIT=true
    elif echo "$BODY" | grep -qiE "BREAKING[ -]CHANGE:"; then
      IS_BREAKING_COMMIT=true
    fi

    REGEX_CONVENTIONAL='^([a-zA-Z]+)(\(([^)]+)\))?!?:[[:space:]]*(.+)$'
    if [[ "$SUBJECT" =~ $REGEX_CONVENTIONAL ]]; then
      TYPE="${BASH_REMATCH[1],,}"
      SCOPE="${BASH_REMATCH[3]:-}"
      DESC="$(convert_emojis "${BASH_REMATCH[4]}")"

      if [[ -n "$SCOPE" ]]; then
        ENTRY="- **${SCOPE}**: ${DESC} ${COMMIT_LINK}"
      else
        ENTRY="- ${DESC} ${COMMIT_LINK}"
      fi

      if [[ "$IS_BREAKING_COMMIT" == "true" ]]; then
        echo "$ENTRY" >> "$BREAKING_FILE"
        HAS_BREAKING=true
      fi

      case "$TYPE" in
        feat)
          echo "$ENTRY" >> "$FEAT_FILE"
          HAS_FEAT=true
          ;;
        fix)
          echo "$ENTRY" >> "$FIX_FILE"
          HAS_FIX=true
          ;;
        perf)
          echo "$ENTRY" >> "$PERF_FILE"
          HAS_FIX=true
          ;;
        refactor)
          echo "$ENTRY" >> "$REFACTOR_FILE"
          ;;
        docs)
          echo "$ENTRY" >> "$DOCS_FILE"
          ;;
        test)
          echo "$ENTRY" >> "$TEST_FILE"
          ;;
        ci|build)
          echo "$ENTRY" >> "$CI_FILE"
          ;;
        chore)
          echo "$ENTRY" >> "$CHORE_FILE"
          ;;
        revert)
          echo "$ENTRY" >> "$REVERT_FILE"
          HAS_FIX=true
          ;;
        *)
          echo "$ENTRY" >> "$OTHER_FILE"
          ;;
      esac
    else
      CLEAN_SUBJECT="$(convert_emojis "$SUBJECT")"
      ENTRY="- ${CLEAN_SUBJECT} ${COMMIT_LINK}"
      if [[ "$IS_BREAKING_COMMIT" == "true" ]]; then
        echo "$ENTRY" >> "$BREAKING_FILE"
        HAS_BREAKING=true
      fi
      echo "$ENTRY" >> "$OTHER_FILE"
    fi
  done <<< "$COMMITS_RAW"
fi

log "📊 Analyzed $TOTAL_COMMITS relevant commits (Breaking: $HAS_BREAKING, Feat: $HAS_FEAT, Fix: $HAS_FIX)"

# ─────────────────────────────────────────────────────────────
# Geração / Obtenção das Notas de Release
# ─────────────────────────────────────────────────────────────
NOTES_FILE="$TEMP_DIR/release_notes.md"
touch "$NOTES_FILE"

if [[ -n "$INPUT_RELEASE_NOTES" ]]; then
  echo "$INPUT_RELEASE_NOTES" > "$NOTES_FILE"
  HAS_CHANGES=true
else
  append_section() {
    local title="$1"
    local file="$2"
    if [[ -s "$file" ]]; then
      echo "### $title" >> "$NOTES_FILE"
      convert_emojis < "$file" >> "$NOTES_FILE"
      echo "" >> "$NOTES_FILE"
    fi
  }

  append_section "⚠️ Breaking Changes" "$BREAKING_FILE"
  append_section "🚀 Features" "$FEAT_FILE"
  append_section "🐛 Bug Fixes" "$FIX_FILE"
  append_section "⚡ Performance Improvements" "$PERF_FILE"
  append_section "♻️ Code Refactoring" "$REFACTOR_FILE"
  append_section "📝 Documentation" "$DOCS_FILE"
  append_section "🧪 Tests" "$TEST_FILE"
  append_section "🔧 CI & Build System" "$CI_FILE"
  append_section "📦 Miscellaneous" "$CHORE_FILE"
  append_section "⏪ Reverts" "$REVERT_FILE"
  append_section "🔄 Other Changes" "$OTHER_FILE"

  HAS_CHANGES=false
  if [[ -s "$NOTES_FILE" ]]; then
    HAS_CHANGES=true
  fi
fi

# Se não há mudanças identificadas e nenhuma versão explícita foi dada
if [[ "$HAS_CHANGES" == "false" && -z "$INPUT_VERSION" ]]; then
  log "ℹ️ No changes detected since last release ($LAST_TAG). No new release needed."
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

# ─────────────────────────────────────────────────────────────
# Resolução de Versão
# ─────────────────────────────────────────────────────────────
RESOLVED_VERSION=""
RESOLVED_TAG=""

if [[ -n "$INPUT_VERSION" && "$INPUT_VERSION" != "Unreleased" ]]; then
  RESOLVED_VERSION="$INPUT_VERSION"
  RESOLVED_TAG="$RESOLVED_VERSION"
else
  FORMAT="${VERSION_FORMAT:-v%major.%minor.%patch}"

  # Se a branch de release contiver versão no nome (ex: release-1.0.0, release/v1.0.0)
  BRANCH_TARGET_SEMVER=""
  if [[ "$CURRENT_BRANCH" =~ ^release[-/][vV]?([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
    BRANCH_TARGET_SEMVER="${BASH_REMATCH[1]}"
    if [[ "$BRANCH_TARGET_SEMVER" =~ ^[0-9]+\.[0-9]+$ ]]; then
      BRANCH_TARGET_SEMVER="${BRANCH_TARGET_SEMVER}.0"
    fi
  fi

  # Se estiver na branch main (release) e a última tag for um pre-release (ex: v1.0.0-rc.2),
  # a versão limpa alvo é o prefixo semântico dessa tag pre-release
  PRERELEASE_TARGET_SEMVER=""
  if [[ "$MODE" == "release" && -n "$LAST_TAG" && "$LAST_TAG" =~ - ]]; then
    CLEAN_FROM_TAG="${LAST_TAG#v}"
    CLEAN_FROM_TAG="${CLEAN_FROM_TAG%%-*}"
    if [[ "$CLEAN_FROM_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      PRERELEASE_TARGET_SEMVER="$CLEAN_FROM_TAG"
    fi
  fi

  if [[ -n "$PRERELEASE_TARGET_SEMVER" ]]; then
    IFS='.' read -r MAJOR MINOR PATCH <<< "$PRERELEASE_TARGET_SEMVER"
  elif [[ -n "$BRANCH_TARGET_SEMVER" ]]; then
    IFS='.' read -r MAJOR MINOR PATCH <<< "$BRANCH_TARGET_SEMVER"
  else
    # Calcula SemVer a partir da última tag estável ou LAST_TAG limpa
    BASE_SEMVER="0.0.0"
    if [[ -n "${LAST_STABLE_TAG:-}" ]]; then
      BASE_SEMVER="${LAST_STABLE_TAG#v}"
    elif [[ -n "$LAST_TAG" ]]; then
      BASE_SEMVER="${LAST_TAG#v}"
    fi

    IFS='.' read -r MAJOR MINOR PATCH <<< "${BASE_SEMVER%%-*}"
    MAJOR="${MAJOR:-0}"
    MINOR="${MINOR:-0}"
    PATCH="${PATCH:-0}"

    if [[ "$HAS_BREAKING" == "true" ]]; then
      MAJOR=$((MAJOR + 1))
      MINOR=0
      PATCH=0
    elif [[ "$HAS_FEAT" == "true" ]]; then
      MINOR=$((MINOR + 1))
      PATCH=0
    else
      PATCH=$((PATCH + 1))
    fi
  fi

  YEAR_4="$(date +"%Y")"
  YEAR_2="$(date +"%y")"
  MONTH_2="$(date +"%m")"
  MONTH_1="$(date +"%-m" 2>/dev/null || echo "$((10#$MONTH_2))")"
  DAY_2="$(date +"%d")"
  DAY_1="$(date +"%-d" 2>/dev/null || echo "$((10#$DAY_2))")"

  RESOLVED_VERSION="$FORMAT"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%MAJOR/$MAJOR}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%major/$MAJOR}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%MINOR/$MINOR}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%minor/$MINOR}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%PATCH/$PATCH}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%patch/$PATCH}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%path/$PATCH}"

  RESOLVED_VERSION="${RESOLVED_VERSION//\%YYYY/$YEAR_4}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%YY/$YEAR_2}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%mm/$MONTH_2}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%dd/$DAY_2}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%m/$MONTH_1}"
  RESOLVED_VERSION="${RESOLVED_VERSION//\%d/$DAY_1}"

  if [[ "$MODE" == "prerelease" ]]; then
    if [[ "$PRERELEASE_STRATEGY" == "rc" ]]; then
      CLEAN_TAG="$RESOLVED_VERSION"
      EXISTING_RCS=$(git tag -l "${CLEAN_TAG}-${PRERELEASE_SUFFIX}.*" 2>/dev/null | sort -V || true)
      if [[ -n "$EXISTING_RCS" ]]; then
        LATEST_RC="$(echo "$EXISTING_RCS" | tail -n 1)"
        RC_NUM="${LATEST_RC##*.}"
        if [[ "$RC_NUM" =~ ^[0-9]+$ ]]; then
          NEXT_NUM=$((RC_NUM + 1))
        else
          NEXT_NUM=1
        fi
      else
        NEXT_NUM=1
      fi
      RESOLVED_VERSION="${CLEAN_TAG}-${PRERELEASE_SUFFIX}.${NEXT_NUM}"
    fi
  else
    # Evita duplicar tag existente se for formato por data
    if [[ -z "$PRERELEASE_TARGET_SEMVER" ]] && git rev-parse "$RESOLVED_VERSION" >/dev/null 2>&1; then
      COUNT=1
      while git rev-parse "${RESOLVED_VERSION}.${COUNT}" >/dev/null 2>&1; do
        COUNT=$((COUNT + 1))
      done
      RESOLVED_VERSION="${RESOLVED_VERSION}.${COUNT}"
    fi
  fi

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
    if [[ "$PRERELEASE_STRATEGY" == "rc" ]]; then
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
