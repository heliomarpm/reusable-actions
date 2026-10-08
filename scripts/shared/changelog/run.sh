#!/usr/bin/env bash
set -Eeuo pipefail

# ─────────────────────────────────────────────────────────────
# Actions Changelog - Native Zero-Dependency Changelog Engine
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

log "🚀 Changelog Action - Initializing"

# ─────────────────────────────────────────────────────────────
# Inputs & Configuration
# ─────────────────────────────────────────────────────────────
CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"
CHANGELOG_TITLE="${CHANGELOG_TITLE:-"# 📦 Changelog\n\nAll notable changes to this project will be documented in this file."}"
PROJECT_PATH="${PROJECT_PATH:-.}"
INPUT_BRANCH="${INPUT_BRANCH:-}"
RELEASE_BRANCHES="${RELEASE_BRANCHES:-main,master}"
DEVELOP_BRANCHES="${DEVELOP_BRANCHES:-develop,dev}"
PRERELEASE_BRANCHES="${PRERELEASE_BRANCHES:-release-*,release/*}"
PRERELEASE_STRATEGY="${PRERELEASE_STRATEGY:-rc}"
PRERELEASE_SUFFIX="${PRERELEASE_SUFFIX:-rc}"
INPUT_VERSION="${INPUT_VERSION:-}"
VERSION_FORMAT="${VERSION_FORMAT:-}"
COMMIT_CHANGELOG="${COMMIT_CHANGELOG:-true}"
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
  # Se não houver tag, busca o commit do último release registrado
  LAST_RELEASE_COMMIT="$(git log -n 1 --grep="^chore(release)" --grep="^chore(changelog)" --format="%H" 2>/dev/null || true)"
  if [[ -n "$LAST_RELEASE_COMMIT" && "$LAST_RELEASE_COMMIT" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
    RANGE="${LAST_RELEASE_COMMIT}..HEAD"
    SINCE_LABEL="commit de release '${LAST_RELEASE_COMMIT:0:7}'"
  elif [[ "$MODE" == "develop" ]]; then
    RELEASE_BASE=""
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      RELEASE_BASE="origin/main"
    elif git rev-parse --verify main >/dev/null 2>&1; then
      RELEASE_BASE="main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
      RELEASE_BASE="origin/master"
    elif git rev-parse --verify master >/dev/null 2>&1; then
      RELEASE_BASE="master"
    fi

    if [[ -n "$RELEASE_BASE" ]]; then
      MERGE_BASE="$(git merge-base "$RELEASE_BASE" HEAD 2>/dev/null || true)"
      if [[ -n "$MERGE_BASE" && "$MERGE_BASE" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
        RANGE="${MERGE_BASE}..HEAD"
        SINCE_LABEL="base branch $RELEASE_BASE ('${MERGE_BASE:0:7}')"
      fi
    fi
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
  # Tenta inferir da URL remota do git
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

# Coleta commits usando separadores seguros ASCII 0x1f (Unit Separator) e 0x1e (Record Separator)
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

    # Formata link do commit
    if [[ -n "$REPO_URL" ]]; then
      COMMIT_LINK="([${SHORT_HASH}](${REPO_URL}/commit/${FULL_HASH}))"
    else
      COMMIT_LINK="(${SHORT_HASH})"
    fi

    # Detecta se é breaking change no subject ou no body
    IS_BREAKING_COMMIT=false
    if echo "$SUBJECT" | grep -qE "^[a-zA-Z]+(\([^\)]+\))?!:"; then
      IS_BREAKING_COMMIT=true
    elif echo "$BODY" | grep -qiE "BREAKING[ -]CHANGE:"; then
      IS_BREAKING_COMMIT=true
    fi

    # Analisa Conventional Commit: tipo(escopo opcional)!?: descrição
    REGEX_CONVENTIONAL='^([a-zA-Z]+)(\(([^)]+)\))?!?:[[:space:]]*(.+)$'
    if [[ "$SUBJECT" =~ $REGEX_CONVENTIONAL ]]; then
      TYPE="${BASH_REMATCH[1],,}" # lowercase
      SCOPE="${BASH_REMATCH[3]:-}"
      DESC="$(convert_emojis "${BASH_REMATCH[4]}")"

      # Monta linha formatada
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
          HAS_FIX=true # perf também conta como bump patch se não houver fix
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
      # Commit não convencional
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
# Geração das Notas em Markdown
# ─────────────────────────────────────────────────────────────
NOTES_FILE="$TEMP_DIR/release_notes.md"
touch "$NOTES_FILE"

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

# Se não há notas geradas neste range, mas já havia [Unreleased] no changelog:
# No modo release, usaremos o conteúdo pré-existente de [Unreleased] para promover a versão!
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
elif [[ ("$MODE" == "release" || "$MODE" == "prerelease") && -s "$EXISTING_UNRELEASED_CONTENT" ]]; then
  HAS_CHANGES=true
  # Usa o conteúdo existente de unreleased como release notes
  cat "$EXISTING_UNRELEASED_CONTENT" > "$NOTES_FILE"
fi

HAS_BUMP=false
if [[ "$HAS_BREAKING" == "true" || "$HAS_FEAT" == "true" || "$HAS_FIX" == "true" ]]; then
  HAS_BUMP=true
fi

if [[ -s "$EXISTING_UNRELEASED_CONTENT" ]]; then
  if grep -qiE "Breaking Changes|Features|Bug Fixes|Performance Improvements|Reverts" "$EXISTING_UNRELEASED_CONTENT"; then
    HAS_BUMP=true
  fi
fi

PRERELEASE_PROMOTION=false
if [[ "$MODE" == "release" && -n "$LAST_TAG" && "$LAST_TAG" =~ - ]]; then
  PRERELEASE_PROMOTION=true
fi

if [[ "$MODE" != "develop" && "$HAS_BUMP" == "false" && "$PRERELEASE_PROMOTION" == "false" && ( -z "$INPUT_VERSION" || "$INPUT_VERSION" == "Unreleased" ) ]]; then
  log "ℹ️ No SemVer-impacting changes detected since last release ($LAST_TAG). No new changelog version needed."
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

if [[ "$HAS_CHANGES" == "false" && "$MODE" != "develop" ]]; then
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
# ─────────────────────────────────────────────────────────────
RESOLVED_VERSION=""
RESOLVED_TAG=""
TODAY="$(date +"%Y-%m-%d")"

if [[ "$MODE" == "develop" || "$MODE" == "preview" ]]; then
  RESOLVED_VERSION="Unreleased"
  SECTION_HEADER="## [Unreleased]"
else
  # Modo release ou prerelease
  if [[ -n "$INPUT_VERSION" && "$INPUT_VERSION" != "Unreleased" ]]; then
    RESOLVED_VERSION="$INPUT_VERSION"
    RESOLVED_TAG="$RESOLVED_VERSION"
  else
    # 1. Determina o template de formato (se não fornecido explicitamente)
    FORMAT="$VERSION_FORMAT"
    if [[ -z "$FORMAT" ]]; then
      if [[ "$MODE" == "release" || "$MODE" == "prerelease" || -n "$LAST_TAG" ]]; then
        FORMAT="v%major.%minor.%patch"
      else
        FORMAT="%YYYY-%mm-%dd"
      fi
    fi

    # Se a branch contiver versão no nome (ex: release-1.0.0, release/v1.0.0)
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
      if [[ "$CLEAN_FROM_TAG" =~ ^[0-9]+\.[0-9]+$ ]]; then
        PRERELEASE_TARGET_SEMVER="$CLEAN_FROM_TAG"
      fi
    fi

    if [[ -n "$PRERELEASE_TARGET_SEMVER" ]]; then
      IFS='.' read -r MAJOR MINOR PATCH <<< "$PRERELEASE_TARGET_SEMVER"
    elif [[ -n "$BRANCH_TARGET_SEMVER" ]]; then
      IFS='.' read -r MAJOR MINOR PATCH <<< "$BRANCH_TARGET_SEMVER"
    else
      # 2. Calcula SemVer (Major, Minor, Patch)
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
      elif [[ "$HAS_FIX" == "true" ]]; then
        PATCH=$((PATCH + 1))
      fi
    fi

    # 3. Extrai partes de data
    YEAR_4="$(date +"%Y")"
    YEAR_2="$(date +"%y")"
    MONTH_2="$(date +"%m")"
    MONTH_1="$(date +"%-m" 2>/dev/null || echo "$((10#$MONTH_2))")"
    DAY_2="$(date +"%d")"
    DAY_1="$(date +"%-d" 2>/dev/null || echo "$((10#$DAY_2))")"

    # 4. Substituição de Tokens no template
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
      # 5. Evita duplicação caso seja versão puramente por data
      if [[ -z "$PRERELEASE_TARGET_SEMVER" ]] && [[ -f "$CHANGELOG_FILE" ]] && grep -qE "^## \[${RESOLVED_VERSION}\]" "$CHANGELOG_FILE" 2>/dev/null; then
        COUNT=1
        while grep -qE "^## \[${RESOLVED_VERSION}\.${COUNT}\]" "$CHANGELOG_FILE" 2>/dev/null; do
          COUNT=$((COUNT + 1))
        done
        RESOLVED_VERSION="${RESOLVED_VERSION}.${COUNT}"
      fi
    fi

    RESOLVED_TAG="$RESOLVED_VERSION"
  fi

  # Monta o cabeçalho no CHANGELOG.md
  if [[ "$RESOLVED_VERSION" =~ [0-9]{4}[.-][0-9]{2} ]]; then
    SECTION_HEADER="## [${RESOLVED_VERSION}]"
  else
    SECTION_HEADER="## [${RESOLVED_VERSION}] - ${TODAY}"
  fi
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
  fi
} > "$NEW_SECTION_FILE"

UPDATED_CHANGELOG="$TEMP_DIR/CHANGELOG.updated.md"

awk -v new_sec_file="$NEW_SECTION_FILE" '
  BEGIN {
    inserted = 0
    skipping_unreleased = 0
  }

  /^## \[Unreleased\]/ {
    # Substitui a seção unreleased existente
    while ((getline line < new_sec_file) > 0) {
      print line
    }
    close(new_sec_file)
    inserted = 1
    skipping_unreleased = 1
    next
  }

  /^## \[/ {
    # Se estávamos ignorando o unreleased antigo, agora paramos ao encontrar a próxima versão
    if (skipping_unreleased) {
      skipping_unreleased = 0
    }
    # Se ainda não havíamos inserido (não tinha [Unreleased] prévio), inserimos logo antes da primeira versão
    if (!inserted) {
      while ((getline line < new_sec_file) > 0) {
        print line
      }
      close(new_sec_file)
      inserted = 1
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
    # Se o arquivo não continha nenhuma versão (apenas cabeçalho)
    if (!inserted) {
      print ""
      while ((getline line < new_sec_file) > 0) {
        print line
      }
      close(new_sec_file)
    }
  }
' "$CHANGELOG_FILE" > "$UPDATED_CHANGELOG"

cp "$UPDATED_CHANGELOG" "$CHANGELOG_FILE"
log "✅ $CHANGELOG_FILE updated successfully"

# ─────────────────────────────────────────────────────────────
# Commit & Push do CHANGELOG.md (se configurado)
# ─────────────────────────────────────────────────────────────
if [[ "$COMMIT_CHANGELOG" == "true" ]]; then
  git config user.name "${GIT_USER_NAME:-github-actions[bot]}"
  git config user.email "${GIT_USER_EMAIL:-github-actions[bot]@users.noreply.github.com}"

  if [[ -n "$COMMIT_MESSAGE" ]]; then
    MSG="$COMMIT_MESSAGE"
  elif [[ "$MODE" == "release" ]]; then
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
