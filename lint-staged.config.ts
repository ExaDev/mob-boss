const typecheck = () => "tsc -p tsconfig.json --noEmit";

export default {
  "{release.config.mjs,*.ts,scripts/**/*.ts}": [typecheck],
};
