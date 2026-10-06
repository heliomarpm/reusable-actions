const path = require('path');
const fs = require('fs');
const base = require(path.resolve(__dirname, '../../shared/semantic-release/default-releaserc.json'));

// Descobre dinamicamente a localização do package.json (pkgRoot)
let rawPath = process.env.PROJECT_PATH || '.';
if (path.isAbsolute(rawPath) && rawPath.startsWith(process.cwd())) {
  rawPath = path.relative(process.cwd(), rawPath) || '.';
}
let pkgRoot = rawPath.replace(/^\.\//, '').replace(/\/$/, '') || '.';

if (!fs.existsSync(path.resolve(process.cwd(), pkgRoot, 'package.json'))) {
  if (fs.existsSync(path.resolve(process.cwd(), 'package.json'))) {
    pkgRoot = '.';
  } else if (fs.existsSync(path.resolve(process.cwd(), 'app', 'package.json'))) {
    pkgRoot = 'app';
  } else {
    try {
      const entries = fs.readdirSync(process.cwd(), { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules' && entry.name !== '__reusable_actions__' && entry.name !== 'vendor') {
          if (fs.existsSync(path.resolve(process.cwd(), entry.name, 'package.json'))) {
            pkgRoot = entry.name;
            break;
          }
        }
      }
    } catch (_) {}
  }
}

// Assets a serem incluídos no commit de release
const gitAssets = ['CHANGELOG.md'];
if (pkgRoot === '.') {
  gitAssets.push('package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml');
} else {
  gitAssets.push(
    `${pkgRoot}/package.json`,
    `${pkgRoot}/package-lock.json`,
    `${pkgRoot}/yarn.lock`,
    `${pkgRoot}/pnpm-lock.yaml`,
    `${pkgRoot}/CHANGELOG.md`
  );
}

// Clona e enriquece os plugins do base com as especificidades do Node.js
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

// Insere o plugin npm logo antes do git com o pkgRoot correto
const gitIndex = plugins.findIndex(p => (Array.isArray(p) ? p[0] : p) === '@semantic-release/git');
if (gitIndex !== -1) {
  plugins.splice(gitIndex, 0, [
    '@semantic-release/npm',
    {
      npmPublish: false,
      pkgRoot: pkgRoot
    }
  ]);
}

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
