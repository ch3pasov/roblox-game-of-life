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
    if (result.changes.universeSettings) console.log("Updated universe experience settings.");
    if (result.changes.rootPlaceSettings) console.log("Updated root place settings.");
    if (result.changes.icon) console.log("Uploaded game icon.");
    if (result.changes.thumbnails) console.log("Uploaded game thumbnails.");
    for (const field of result.unsupported ?? []) {
      console.log(`WARN ${field} is tracked in metadata config but is not supported by the current Open Cloud sync.`);
    }
    for (const warning of result.warnings ?? []) {
      console.log(`WARN ${warning}`);
    }
    if (!result.changed) console.log("No filled metadata fields to update.");
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
