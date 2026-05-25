#!/usr/bin/env node

import path from "node:path";
import process from "node:process";
import {
  DEFAULT_PLACE_OUTPUT,
  buildPlace,
  deployPlace,
  loadDotEnv,
  publishPlace
} from "./lib/roblox-open-cloud.mjs";

function parseArgs(argv) {
  const args = {
    command: "deploy",
    outputPath: DEFAULT_PLACE_OUTPUT,
    versionType: "Published"
  };

  const positional = [];
  for (const arg of argv) {
    if (arg.startsWith("--output=")) {
      args.outputPath = path.resolve(process.cwd(), arg.slice("--output=".length));
    } else if (arg.startsWith("--versionType=")) {
      args.versionType = arg.slice("--versionType=".length);
    } else {
      positional.push(arg);
    }
  }

  if (positional[0]) {
    args.command = positional[0];
  }

  return args;
}

function usage() {
  console.log("Usage:");
  console.log("  node scripts/roblox-publish.mjs build");
  console.log("  node scripts/roblox-publish.mjs publish");
  console.log("  node scripts/roblox-publish.mjs deploy");
  console.log("");
  console.log("Options:");
  console.log("  --output=build/game-of-life.rbxl");
  console.log("  --versionType=Published");
}

function printPublishResult(result) {
  console.log(`Published place.`);
  if (result?.versionNumber) {
    console.log(`Roblox version number: ${result.versionNumber}`);
  }
}

loadDotEnv();

const args = parseArgs(process.argv.slice(2));
try {
  if (args.command === "build") {
    const outputPath = await buildPlace({ outputPath: args.outputPath });
    console.log(`Built place file: ${outputPath}`);
  } else if (args.command === "publish") {
    const result = await publishPlace({ outputPath: args.outputPath, versionType: args.versionType });
    printPublishResult(result);
  } else if (args.command === "deploy") {
    const result = await deployPlace({ outputPath: args.outputPath, versionType: args.versionType });
    console.log(`Built place file: ${result.outputPath}`);
    printPublishResult(result.result);
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
