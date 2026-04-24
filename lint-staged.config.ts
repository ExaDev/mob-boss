const typecheck = () => "tsc -p tsconfig.json --noEmit";

export default {
  "{release.config.mjs,scripts/sync-version.ts}": [typecheck],
};
