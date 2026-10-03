const path = require('path');
const base = require(path.resolve(__dirname, '../../shared/semantic-release/default-releaserc.json'));

// Clona e enriquece os plugins do base com as especificidades do Node.js
const plugins = base.plugins.map(plugin => {
  const name = Array.isArray(plugin) ? plugin[0] : plugin;
  if (name === '@semantic-release/git') {
    return [
      '@semantic-release/git',
      {
        assets: [
          'CHANGELOG.md',
          'package.json',
          'package-lock.json',
          'yarn.lock',
          'pnpm-lock.yaml'
        ],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}'
      }
    ];
  }
  return plugin;
});

// Insere o plugin npm logo antes do git
const gitIndex = plugins.findIndex(p => (Array.isArray(p) ? p[0] : p) === '@semantic-release/git');
if (gitIndex !== -1) {
  plugins.splice(gitIndex, 0, [
    '@semantic-release/npm',
    {
      npmPublish: false,
      pkgRoot: '.'
    }
  ]);
}

module.exports = {
  ...base,
  plugins
};
