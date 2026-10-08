const path = require('path');
const base = require(path.resolve(__dirname, 'default-releaserc.json'));

const skipChangelog = process.env.SEMANTIC_RELEASE_SKIP_CHANGELOG === 'true' || process.env.ENABLE_CHANGELOG === 'false';
const prereleaseStrategy = process.env.PRERELEASE_STRATEGY || 'rc';
const prereleaseSuffix = process.env.PRERELEASE_SUFFIX || 'rc';

const branches = base.branches.map(b => {
  if (typeof b === 'object' && b.name === 'release-*') {
    if (prereleaseStrategy === 'same-tag') {
      return { ...b, prerelease: false };
    }
    return { ...b, prerelease: prereleaseSuffix };
  }
  return b;
});

let plugins = base.plugins.filter(plugin => {
  const name = Array.isArray(plugin) ? plugin[0] : plugin;
  if (skipChangelog && (name === '@semantic-release/changelog' || name === '@semantic-release/git')) {
    return false;
  }
  return true;
});

module.exports = {
  ...base,
  branches,
  plugins
};
