// @ts-check

/** @type {Partial<import('semantic-release').GlobalConfig>} */
const config = {
  branches: ["main"],
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/exec",
      {
        prepareCmd: "pnpm tsx scripts/sync-version.ts ${nextRelease.version}",
      },
    ],
    [
      "@semantic-release/git",
      {
        assets: [
          "package.json",
          "plugins/mob-boss/.claude-plugin/plugin.json",
          ".claude-plugin/marketplace.json",
        ],
        message: "chore(release): v${nextRelease.version} [skip ci]",
      },
    ],
    "@semantic-release/github",
  ],
};

export default /** @type {import('semantic-release').GlobalConfig} */ (config);
