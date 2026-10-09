#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

  NODE_BIN="node"
  if ! command -v node >/dev/null 2>&1; then
    if command -v node.exe >/dev/null 2>&1; then
      NODE_BIN="node.exe"
    elif [[ -x "/mnt/c/Program Files/nodejs/node.exe" ]]; then
      NODE_BIN="/mnt/c/Program Files/nodejs/node.exe"
    fi
  fi
  export NODE_BIN
  export WSLENV="SEMANTIC_RELEASE_SKIP_VERSION:SEMANTIC_RELEASE_SKIP_CHANGELOG:CHANGELOG_TITLE:SEMANTIC_RELEASE_CHANGELOG_TITLE:PRERELEASE_INCREMENTAL:PRERELEASE_STRATEGY:PRERELEASE_SUFFIX:${WSLENV:-}"
}

@test "semantic-release/node: configura plugins padrao quando skips sao falso" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export SEMANTIC_RELEASE_SKIP_VERSION="false"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="false"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/node/releaserc.js");
    const pluginNames = config.plugins.map(p => Array.isArray(p) ? p[0] : p);
    if (!pluginNames.includes("@semantic-release/npm")) process.exit(1);
    if (!pluginNames.includes("@semantic-release/changelog")) process.exit(2);
    const gitPlugin = config.plugins.find(p => Array.isArray(p) && p[0] === "@semantic-release/git");
    if (!gitPlugin || !gitPlugin[1].assets.includes("package.json") || !gitPlugin[1].assets.includes("CHANGELOG.md")) process.exit(3);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/node: remove npm plugin e package.json quando skip-version-file for true" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export SEMANTIC_RELEASE_SKIP_VERSION="true"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="false"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/node/releaserc.js");
    const pluginNames = config.plugins.map(p => Array.isArray(p) ? p[0] : p);
    if (pluginNames.includes("@semantic-release/npm")) process.exit(1);
    const gitPlugin = config.plugins.find(p => Array.isArray(p) && p[0] === "@semantic-release/git");
    if (!gitPlugin || gitPlugin[1].assets.includes("package.json")) process.exit(2);
    if (!gitPlugin[1].assets.includes("CHANGELOG.md")) process.exit(3);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/node: remove changelog e git plugin quando ambos skips forem true" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export SEMANTIC_RELEASE_SKIP_VERSION="true"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="true"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/node/releaserc.js");
    const pluginNames = config.plugins.map(p => Array.isArray(p) ? p[0] : p);
    if (pluginNames.includes("@semantic-release/npm")) process.exit(1);
    if (pluginNames.includes("@semantic-release/changelog")) process.exit(2);
    if (pluginNames.includes("@semantic-release/git")) process.exit(3);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/php: remove composer.json e git plugin conforme opcoes de skip" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export SEMANTIC_RELEASE_SKIP_VERSION="true"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="false"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/php/releaserc.js");
    const gitPlugin = config.plugins.find(p => Array.isArray(p) && p[0] === "@semantic-release/git");
    if (!gitPlugin || gitPlugin[1].assets.includes("composer.json")) process.exit(1);
    if (!gitPlugin[1].assets.includes("CHANGELOG.md")) process.exit(2);
  '
  [ "$status" -eq 0 ]

  export SEMANTIC_RELEASE_SKIP_VERSION="true"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="true"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/php/releaserc.js");
    const pluginNames = config.plugins.map(p => Array.isArray(p) ? p[0] : p);
    if (pluginNames.includes("@semantic-release/changelog")) process.exit(1);
    if (pluginNames.includes("@semantic-release/git")) process.exit(2);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/generic: remove changelog e git plugin em default-releaserc.js quando skip-changelog for true" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export SEMANTIC_RELEASE_SKIP_CHANGELOG="true"

  run "$NODE_BIN" -e '
    const config = require("./scripts/shared/semantic-release/default-releaserc.js");
    const pluginNames = config.plugins.map(p => Array.isArray(p) ? p[0] : p);
    if (pluginNames.includes("@semantic-release/changelog")) process.exit(1);
    if (pluginNames.includes("@semantic-release/git")) process.exit(2);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/generic: customiza changelogTitle em default-releaserc.js via CHANGELOG_TITLE" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export CHANGELOG_TITLE="# 🚀 Custom Title\n\nCustom description"

  run "$NODE_BIN" -e '
    const config = require("./scripts/shared/semantic-release/default-releaserc.js");
    const changelogPlugin = config.plugins.find(p => Array.isArray(p) && p[0] === "@semantic-release/changelog");
    if (!changelogPlugin) process.exit(1);
    if (!changelogPlugin[1].changelogTitle.includes("# 🚀 Custom Title")) process.exit(2);
    if (!changelogPlugin[1].changelogTitle.includes("Custom description")) process.exit(3);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/node: customiza changelogTitle em node/releaserc.js via CHANGELOG_TITLE" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export CHANGELOG_TITLE="# 🚀 Custom Node Title\n\nCustom node description"

  run "$NODE_BIN" -e '
    const config = require("./scripts/plugins/node/releaserc.js");
    const changelogPlugin = config.plugins.find(p => Array.isArray(p) && p[0] === "@semantic-release/changelog");
    if (!changelogPlugin) process.exit(1);
    if (!changelogPlugin[1].changelogTitle.includes("# 🚀 Custom Node Title")) process.exit(2);
    if (!changelogPlugin[1].changelogTitle.includes("Custom node description")) process.exit(3);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/generic: release-* recebe prerelease suffix quando PRERELEASE_INCREMENTAL=true" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export PRERELEASE_INCREMENTAL="true"
  export PRERELEASE_SUFFIX="beta"

  run "$NODE_BIN" -e '
    delete require.cache[require.resolve("./scripts/shared/semantic-release/default-releaserc.js")];
    const config = require("./scripts/shared/semantic-release/default-releaserc.js");
    const relBranch = config.branches.find(b => typeof b === "object" && b.name === "release-*");
    if (!relBranch || relBranch.prerelease !== "beta") process.exit(1);
  '
  [ "$status" -eq 0 ]
}

@test "semantic-release/generic: release-* recebe prerelease=false quando PRERELEASE_INCREMENTAL=false" {
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    skip "node/node.exe não disponível no ambiente"
  fi

  cd "$ROOT_DIR"
  export PRERELEASE_INCREMENTAL="false"

  run "$NODE_BIN" -e '
    delete require.cache[require.resolve("./scripts/shared/semantic-release/default-releaserc.js")];
    const config = require("./scripts/shared/semantic-release/default-releaserc.js");
    const relBranch = config.branches.find(b => typeof b === "object" && b.name === "release-*");
    if (!relBranch || relBranch.prerelease !== false) process.exit(1);
  '
  [ "$status" -eq 0 ]
}
