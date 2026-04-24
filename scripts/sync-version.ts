import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const version: string = process.argv[2];

if (!version) {
  console.error("Usage: tsx scripts/sync-version.ts <version>");
  process.exit(1);
}

interface PackageJson {
  version: string;
  [key: string]: unknown;
}

interface PluginManifest {
  version: string;
  [key: string]: unknown;
}

interface Marketplace {
  plugins: Array<{ version: string; [key: string]: unknown }>;
  [key: string]: unknown;
}

const files = [
  {
    path: resolve(__dirname, "..", "package.json"),
    update: (data: PackageJson) => {
      data.version = version;
    },
  },
  {
    path: resolve(__dirname, "..", "plugins", "mob-boss", ".claude-plugin", "plugin.json"),
    update: (data: PluginManifest) => {
      data.version = version;
    },
  },
  {
    path: resolve(__dirname, "..", ".claude-plugin", "marketplace.json"),
    update: (data: Marketplace) => {
      data.plugins[0].version = version;
    },
  },
];

for (const { path, update } of files) {
  const raw = readFileSync(path, "utf8");
  const data = JSON.parse(raw);
  update(data);
  writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
  console.log(`Updated ${path} → v${version}`);
}
