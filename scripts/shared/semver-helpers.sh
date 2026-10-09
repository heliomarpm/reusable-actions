#!/usr/bin/env bash
set -euo pipefail

# Guard contra execução dupla
[[ -n "${__SEMVER_HELPERS_LOADED:-}" ]] && return 0
__SEMVER_HELPERS_LOADED=true

# ─────────────────────────────────────────────────────────────
# Conversão de Emojis Shortcodes (ex: :rocket: -> 🚀)
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

# ─────────────────────────────────────────────────────────────
# Pattern matching CSV (com suporte a glob: release-*, release/*)
# ─────────────────────────────────────────────────────────────
matches_pattern_csv() {
  local item="$1"
  local csv="$2"
  local IFS=','
  for entry in $csv; do
    entry="$(echo "$entry" | xargs)" # trim
    # Sem aspas em $entry para permitir glob pattern matching
    if [[ "$item" == $entry ]]; then
      return 0
    fi
  done
  return 1
}

# ─────────────────────────────────────────────────────────────
# Modo de Operação (release, prerelease, develop, preview)
# ─────────────────────────────────────────────────────────────
determine_release_mode() {
  local branch="$1"
  local release_branches="${2:-main,master}"
  local prerelease_branches="${3:-release-*,release/*}"
  local develop_branches="${4:-develop,dev}"

  if matches_pattern_csv "$branch" "$release_branches"; then
    echo "release"
  elif matches_pattern_csv "$branch" "$prerelease_branches"; then
    echo "prerelease"
  elif matches_pattern_csv "$branch" "$develop_branches"; then
    echo "develop"
  else
    echo "preview"
  fi
}

# ─────────────────────────────────────────────────────────────
# Obtenção da URL do repositório GitHub
# ─────────────────────────────────────────────────────────────
get_repo_url() {
  if [[ -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
    echo "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
    return 0
  fi
  local remote_origin
  remote_origin="$(git config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$remote_origin" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)? ]]; then
    echo "https://github.com/${BASH_REMATCH[1]}"
    return 0
  fi
  echo ""
}

# ─────────────────────────────────────────────────────────────
# Determinação do Range de Commits Git
# ─────────────────────────────────────────────────────────────
resolve_commit_range() {
  local mode="$1"
  local last_tag="$2"
  local last_stable_tag="$3"
  local last_release_commit="${4:-}"
  local use_release_commit="${5:-false}"

  if [[ "$mode" == "release" && -n "$last_tag" && "$last_tag" =~ - && -n "$last_stable_tag" ]]; then
    RANGE="${last_stable_tag}..HEAD"
    SINCE_LABEL="última release estável '$last_stable_tag'"
  elif [[ "$use_release_commit" == "true" && -n "$last_release_commit" ]]; then
    RANGE="${last_release_commit}..HEAD"
    SINCE_LABEL="commit de release '${last_release_commit:0:7}'"
  elif [[ -n "$last_tag" ]]; then
    RANGE="${last_tag}..HEAD"
    SINCE_LABEL="tag '$last_tag'"
  elif [[ -n "$last_release_commit" && "$last_release_commit" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
    RANGE="${last_release_commit}..HEAD"
    SINCE_LABEL="commit de release '${last_release_commit:0:7}'"
  elif [[ "$mode" == "develop" ]]; then
    local release_base=""
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      release_base="origin/main"
    elif git rev-parse --verify main >/dev/null 2>&1; then
      release_base="main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
      release_base="origin/master"
    elif git rev-parse --verify master >/dev/null 2>&1; then
      release_base="master"
    fi
    if [[ -n "$release_base" ]]; then
      local merge_base
      merge_base="$(git merge-base "$release_base" HEAD 2>/dev/null || true)"
      if [[ -n "$merge_base" && "$merge_base" != "$(git rev-parse HEAD 2>/dev/null || true)" ]]; then
        RANGE="${merge_base}..HEAD"
        SINCE_LABEL="base branch $release_base ('${merge_base:0:7}')"
        return 0
      fi
    fi
    RANGE="HEAD"
    SINCE_LABEL="início do repositório"
  else
    RANGE="HEAD"
    SINCE_LABEL="início do repositório"
  fi
}

# ─────────────────────────────────────────────────────────────
# Extração e Parsing de Conventional Commits
# ─────────────────────────────────────────────────────────────
parse_conventional_commits() {
  local range="$1"
  local repo_url="$2"
  local temp_dir="$3"

  local feat_file="$temp_dir/feat.txt"
  local fix_file="$temp_dir/fix.txt"
  local perf_file="$temp_dir/perf.txt"
  local refactor_file="$temp_dir/refactor.txt"
  local docs_file="$temp_dir/docs.txt"
  local test_file="$temp_dir/test.txt"
  local ci_file="$temp_dir/ci.txt"
  local chore_file="$temp_dir/chore.txt"
  local revert_file="$temp_dir/revert.txt"
  local breaking_file="$temp_dir/breaking.txt"
  local other_file="$temp_dir/other.txt"

  touch "$feat_file" "$fix_file" "$perf_file" "$refactor_file" "$docs_file" \
        "$test_file" "$ci_file" "$chore_file" "$revert_file" "$breaking_file" "$other_file"

  local has_breaking=false
  local has_feat=false
  local has_fix=false
  local total_commits=0

  local commits_raw
  commits_raw="$(git log "$range" --no-merges --pretty=format:"%H%x1f%h%x1f%s%x1f%b%x1e" -- . 2>/dev/null || true)"

  if [[ -n "$commits_raw" ]]; then
    while IFS=$'\x1f' read -d $'\x1e' -r full_hash short_hash subject body; do
      full_hash="${full_hash//$'\r'/}"
      full_hash="${full_hash//$'\n'/}"
      full_hash="$(echo "$full_hash" | tr -d '[:space:]')"
      short_hash="${short_hash//$'\r'/}"
      short_hash="${short_hash//$'\n'/}"
      short_hash="$(echo "$short_hash" | tr -d '[:space:]')"
      subject="${subject//$'\r'/}"
      subject="$(echo "$subject" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

      [[ -z "$full_hash" ]] && continue

      if echo "$subject" | grep -qiE "^chore\((release|changelog)\)|^Merge (pull request|branch)|\[(skip ci|ci skip)\]"; then
        continue
      fi

      total_commits=$((total_commits + 1))

      local commit_link
      if [[ -n "$repo_url" ]]; then
        commit_link="([${short_hash}](${repo_url}/commit/${full_hash}))"
      else
        commit_link="(${short_hash})"
      fi

      local is_breaking_commit=false
      if echo "$subject" | grep -qE "^[a-zA-Z]+(\([^\)]+\))?!:"; then
        is_breaking_commit=true
      elif echo "$body" | grep -qiE "BREAKING[ -]CHANGE:"; then
        is_breaking_commit=true
      fi

      local regex_conventional='^([a-zA-Z]+)(\(([^)]+)\))?!?:[[:space:]]*(.+)$'
      if [[ "$subject" =~ $regex_conventional ]]; then
        local type="${BASH_REMATCH[1],,}"
        local scope="${BASH_REMATCH[3]:-}"
        local desc
        desc="$(convert_emojis "${BASH_REMATCH[4]}")"

        local entry
        if [[ -n "$scope" ]]; then
          entry="- **${scope}**: ${desc} ${commit_link}"
        else
          entry="- ${desc} ${commit_link}"
        fi

        if [[ "$is_breaking_commit" == "true" ]]; then
          echo "$entry" >> "$breaking_file"
          has_breaking=true
        fi

        case "$type" in
          feat)
            echo "$entry" >> "$feat_file"
            has_feat=true
            ;;
          fix)
            echo "$entry" >> "$fix_file"
            has_fix=true
            ;;
          perf)
            echo "$entry" >> "$perf_file"
            has_fix=true
            ;;
          refactor)
            echo "$entry" >> "$refactor_file"
            ;;
          docs)
            echo "$entry" >> "$docs_file"
            ;;
          test)
            echo "$entry" >> "$test_file"
            ;;
          ci|build)
            echo "$entry" >> "$ci_file"
            ;;
          chore)
            echo "$entry" >> "$chore_file"
            ;;
          revert)
            echo "$entry" >> "$revert_file"
            has_fix=true
            ;;
          *)
            echo "$entry" >> "$other_file"
            ;;
        esac
      else
        local clean_subject
        clean_subject="$(convert_emojis "$subject")"
        local entry="- ${clean_subject} ${commit_link}"
        if [[ "$is_breaking_commit" == "true" ]]; then
          echo "$entry" >> "$breaking_file"
          has_breaking=true
        fi
        echo "$entry" >> "$other_file"
      fi
    done <<< "$commits_raw"
  fi

  cat <<EOF > "$temp_dir/stats.env"
HAS_BREAKING=$has_breaking
HAS_FEAT=$has_feat
HAS_FIX=$has_fix
TOTAL_COMMITS=$total_commits
EOF
}

# ─────────────────────────────────────────────────────────────
# Geração de Release Notes Markdown Categorizado
# ─────────────────────────────────────────────────────────────
build_release_notes_md() {
  local temp_dir="$1"
  local output_notes_file="$2"

  rm -f "$output_notes_file"
  touch "$output_notes_file"

  _append_sec() {
    local title="$1"
    local file="$2"
    if [[ -s "$file" ]]; then
      echo "### $title" >> "$output_notes_file"
      convert_emojis < "$file" >> "$output_notes_file"
      echo "" >> "$output_notes_file"
    fi
  }

  _append_sec "⚠️ Breaking Changes" "$temp_dir/breaking.txt"
  _append_sec "🚀 Features" "$temp_dir/feat.txt"
  _append_sec "🐛 Bug Fixes" "$temp_dir/fix.txt"
  _append_sec "⚡ Performance Improvements" "$temp_dir/perf.txt"
  _append_sec "♻️ Code Refactoring" "$temp_dir/refactor.txt"
  _append_sec "📝 Documentation" "$temp_dir/docs.txt"
  _append_sec "🧪 Tests" "$temp_dir/test.txt"
  _append_sec "🔧 CI & Build System" "$temp_dir/ci.txt"
  _append_sec "📦 Miscellaneous" "$temp_dir/chore.txt"
  _append_sec "⏪ Reverts" "$temp_dir/revert.txt"
  _append_sec "🔄 Other Changes" "$temp_dir/other.txt"
}

# ─────────────────────────────────────────────────────────────
# Cálculo de Versão SemVer e Pré-Releases
# ─────────────────────────────────────────────────────────────
calculate_semver_version() {
  local mode="$1"
  local base_semver="${2:-0.0.0}"
  local has_breaking="${3:-false}"
  local has_feat="${4:-false}"
  local has_fix="${5:-false}"
  local version_format="${6:-}"
  local prerelease_strategy="${7:-rc}"
  local prerelease_suffix="${8:-rc}"
  local branch_target_semver="${9:-}"
  local prerelease_target_semver="${10:-}"
  local changelog_file="${11:-}"

  local format="${version_format:-v%major.%minor.%patch}"
  local major=0
  local minor=0
  local patch=0

  if [[ -n "$prerelease_target_semver" ]]; then
    IFS='.' read -r major minor patch <<< "$prerelease_target_semver"
  elif [[ -n "$branch_target_semver" ]]; then
    IFS='.' read -r major minor patch <<< "$branch_target_semver"
  else
    IFS='.' read -r major minor patch <<< "${base_semver%%-*}"
    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"

    if [[ "$has_breaking" == "true" ]]; then
      major=$((major + 1))
      minor=0
      patch=0
    elif [[ "$has_feat" == "true" ]]; then
      minor=$((minor + 1))
      patch=0
    elif [[ "$has_fix" == "true" ]]; then
      patch=$((patch + 1))
    fi
  fi

  local year_4 year_2 month_2 month_1 day_2 day_1
  year_4="$(date +"%Y")"
  year_2="$(date +"%y")"
  month_2="$(date +"%m")"
  month_1="$(date +"%-m" 2>/dev/null || echo "$((10#$month_2))")"
  day_2="$(date +"%d")"
  day_1="$(date +"%-d" 2>/dev/null || echo "$((10#$day_2))")"

  local resolved="$format"
  resolved="${resolved//\%MAJOR/$major}"
  resolved="${resolved//\%major/$major}"
  resolved="${resolved//\%MINOR/$minor}"
  resolved="${resolved//\%minor/$minor}"
  resolved="${resolved//\%PATCH/$patch}"
  resolved="${resolved//\%patch/$patch}"
  resolved="${resolved//\%path/$patch}"

  resolved="${resolved//\%YYYY/$year_4}"
  resolved="${resolved//\%YY/$year_2}"
  resolved="${resolved//\%mm/$month_2}"
  resolved="${resolved//\%dd/$day_2}"
  resolved="${resolved//\%m/$month_1}"
  resolved="${resolved//\%d/$day_1}"

  if [[ "$mode" == "prerelease" ]]; then
    if [[ "$prerelease_strategy" == "rc" ]]; then
      local clean_tag="$resolved"
      local existing_rcs
      existing_rcs=$(git tag -l "${clean_tag}-${prerelease_suffix}.*" 2>/dev/null | sort -V || true)
      local next_num=1
      if [[ -n "$existing_rcs" ]]; then
        local latest_rc
        latest_rc="$(echo "$existing_rcs" | tail -n 1)"
        local rc_num="${latest_rc##*.}"
        if [[ "$rc_num" =~ ^[0-9]+$ ]]; then
          next_num=$((rc_num + 1))
        fi
      fi
      resolved="${clean_tag}-${prerelease_suffix}.${next_num}"
    fi
  else
    # Evita duplicar tag ou versão existente (bump patch se for SemVer)
    local check_exists=false
    if git rev-parse "$resolved" >/dev/null 2>&1; then
      check_exists=true
    elif [[ -n "$changelog_file" && -f "$changelog_file" ]] && grep -qE "^## \[${resolved}\]" "$changelog_file" 2>/dev/null; then
      check_exists=true
    fi

    if [[ -z "$prerelease_target_semver" && "$check_exists" == "true" ]]; then
      if [[ "$resolved" =~ ^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local v_prefix="${BASH_REMATCH[1]}"
        local v_maj="${BASH_REMATCH[2]}"
        local v_min="${BASH_REMATCH[3]}"
        local v_pat="${BASH_REMATCH[4]}"
        while git rev-parse "${v_prefix}${v_maj}.${v_min}.${v_pat}" >/dev/null 2>&1 || \
              ([[ -n "$changelog_file" && -f "$changelog_file" ]] && grep -qE "^## \[${v_prefix}${v_maj}\.${v_min}\.${v_pat}\]" "$changelog_file" 2>/dev/null); do
          v_pat=$((v_pat + 1))
        done
        resolved="${v_prefix}${v_maj}.${v_min}.${v_pat}"
      else
        local count=1
        while git rev-parse "${resolved}.${count}" >/dev/null 2>&1 || \
              ([[ -n "$changelog_file" && -f "$changelog_file" ]] && grep -qE "^## \[${resolved}\.${count}\]" "$changelog_file" 2>/dev/null); do
          count=$((count + 1))
        done
        resolved="${resolved}.${count}"
      fi
    fi
  fi

  echo "$resolved"
}
