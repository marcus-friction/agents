import { readFileSync, writeFileSync } from "node:fs";

const source = readFileSync("docs/README.source.md", "utf8");
writeFileSync(
  "README.md",
  `<!-- Generated from docs/README.source.md; do not edit directly. -->\n\n${source}`,
);
