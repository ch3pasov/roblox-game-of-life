#!/usr/bin/env node

import process from "node:process";
import {
  applyMetadata,
  exportMetadata,
  loadDotEnv
} from "./lib/roblox-open-cloud.mjs";

function usage() {
  console.log("Usage:");
  console.log("  node scripts/roblox-metadata.mjs export");
  console.log("  node scripts/roblox-metadata.mjs apply");
}

function printExportResult(result) {
  console.log(`Exported metadata snapshot to ${result.outDir}`);
  for (const item of result.results) {
    console.log(`${item.ok ? "OK" : "WARN"} ${item.label}`);
  }
}

loadDotEnv();

const command = process.argv[2];
try {
  if (command === "export") {
    printExportResult(await exportMetadata());
  } else if (command === "apply") {
    console.log("Creating backup export before applying changes...");
    const result = await applyMetadata();
    printExportResult(result.backup);

    if (result.changes.displayInfo) console.log("Updated display name/description.");
    if (result.changes.icon) console.log("Uploaded game icon.");
    if (result.changes.thumbnails) console.log("Uploaded game thumbnails.");
    if (!result.changed) console.log("No filled metadata fields to update.");
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
