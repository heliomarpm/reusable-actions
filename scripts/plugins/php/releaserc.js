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

module.exports = {
  ...base,
  plugins
};
