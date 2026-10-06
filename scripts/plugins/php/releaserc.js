const path = require('path');
const base = require(path.resolve(__dirname, '../../shared/semantic-release/default-releaserc.json'));

let pkgRoot = (process.env.PROJECT_PATH || '.').replace(/^\.\//, '').replace(/\/$/, '') || '.';
const gitAssets = ['CHANGELOG.md'];
if (pkgRoot === '.') {
  gitAssets.push('composer.json');
} else {
  gitAssets.push(`${pkgRoot}/composer.json`, 'composer.json');
}

// Clona e enriquece os plugins do base com as especificidades do PHP
const plugins = base.plugins.map(plugin => {
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

module.exports = {
  ...base,
  branches,
  plugins
};
