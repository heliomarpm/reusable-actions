const path = require('path');
const base = require(path.resolve(__dirname, '../../shared/semantic-release/default-releaserc.json'));

let pkgRoot = (process.env.PROJECT_PATH || '.').replace(/^\.\//, '').replace(/\/$/, '') || '.';
const pathGitAssets = pkgRoot === '.' ? '' : pkgRoot;

const skipVersion = process.env.SEMANTIC_RELEASE_SKIP_VERSION === 'true';
const skipChangelog = process.env.SEMANTIC_RELEASE_SKIP_CHANGELOG === 'true';

const gitAssets = [];
if (!skipChangelog) {
  gitAssets.push('CHANGELOG.md');

  if (pathGitAssets !== '.') {
    gitAssets.push(`${pathGitAssets}/CHANGELOG.md`);
  }
}
if (!skipVersion) {
  gitAssets.push(`${pathGitAssets}/composer.json`);
}

// Clona e enriquece os plugins do base com as especificidades do PHP
let plugins = base.plugins.map(plugin => {
  const name = Array.isArray(plugin) ? plugin[0] : plugin;
  if (name === '@semantic-release/git') {
    return [
      '@semantic-release/git',
      {
        assets: gitAssets,
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}'
      }
    ];
  }
  return plugin;
});

// Remove changelog plugin if skipped
if (skipChangelog) {
  plugins = plugins.filter(plugin => {
    const name = Array.isArray(plugin) ? plugin[0] : plugin;
    return name !== '@semantic-release/changelog';
  });
} else {
  const changelogTitle = process.env.CHANGELOG_TITLE || process.env.SEMANTIC_RELEASE_CHANGELOG_TITLE;
  if (changelogTitle) {
    plugins = plugins.map(plugin => {
      const name = Array.isArray(plugin) ? plugin[0] : plugin;
      if (name === '@semantic-release/changelog') {
        const opts = Array.isArray(plugin) && plugin[1] ? plugin[1] : {};
        return [
          '@semantic-release/changelog',
          {
            ...opts,
            changelogTitle: changelogTitle.replace(/\\n/g, '\n')
          }
        ];
      }
      return plugin;
    });
  }
}

// Se não houver assets para commit, remove o plugin git
if (gitAssets.length === 0) {
  plugins = plugins.filter(plugin => {
    const name = Array.isArray(plugin) ? plugin[0] : plugin;
    return name !== '@semantic-release/git';
  });
}

const prereleaseIncremental = process.env.PRERELEASE_INCREMENTAL !== 'false' && process.env.PRERELEASE_STRATEGY !== 'same-tag';
const prereleaseSuffix = process.env.PRERELEASE_SUFFIX || 'rc';

const branches = base.branches.map(b => {
  if (typeof b === 'object' && b.name === 'release-*') {
    if (!prereleaseIncremental) {
      return { ...b, prerelease: false };
    }
    return { ...b, prerelease: prereleaseSuffix };
  }
  return b;
});

module.exports = {
  ...base,
  branches,
  plugins
};
