const path = require('path');
const fs = require('fs');
const base = require(path.resolve(__dirname, '../../shared/semantic-release/default-releaserc.json'));

// Descobre dinamicamente a localização do package.json (pkgRoot)
let rawPath = process.env.PROJECT_PATH || '.';
if (path.isAbsolute(rawPath) && rawPath.startsWith(process.cwd())) {
  rawPath = path.relative(process.cwd(), rawPath) || '.';
}
let pkgRoot = rawPath.replace(/^\.\//, '').replace(/\/$/, '') || '.';
const pathGitAssets = pkgRoot === '.' ? '' : `${pkgRoot}/`;

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
    } catch (_) { }
  }
}

// Assets a serem incluídos no commit de release
const skipVersion = process.env.SEMANTIC_RELEASE_SKIP_VERSION === 'true';
const skipChangelog = process.env.SEMANTIC_RELEASE_SKIP_CHANGELOG === 'true';

const gitAssets = [];
if (!skipChangelog) {
  gitAssets.push('CHANGELOG.md');

  if (pathGitAssets !== '.') {
    gitAssets.push(`${pathGitAssets}CHANGELOG.md`);
  }
}

if (!skipVersion) {
  gitAssets.push(
    `${pathGitAssets}package.json`,
    `${pathGitAssets}package-lock.json`,
    `${pathGitAssets}yarn.lock`,
    `${pathGitAssets}pnpm-lock.yaml`
  );
}

// Clona e enriquece os plugins do base com as especificidades do Node.js
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

// Insere o plugin npm logo antes do git com o pkgRoot correto
if (!skipVersion) {
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
