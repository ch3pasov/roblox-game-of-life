#!/usr/bin/env node

import { mkdir, readFile } from "node:fs/promises";
import { existsSync, readFileSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();
const projectPath = path.join(rootDir, "default.project.json");
const configPath = path.join(rootDir, "metadata", "roblox-metadata.json");
const envPath = path.join(rootDir, ".env");
const defaultOutputPath = path.join(rootDir, "build", "game-of-life.rbxl");

function loadDotEnv(filePath) {
  if (!existsSync(filePath)) return;
  const text = readFileSync(filePath, "utf8");
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) continue;
    const [, key, rawValue] = match;
    if (process.env[key]) continue;
    process.env[key] = rawValue.replace(/^["']|["']$/g, "");
  }
}

function parseArgs(argv) {
  const args = {
    command: "deploy",
    outputPath: defaultOutputPath,
    versionType: "Published"
  };

  const positional = [];
  for (const arg of argv) {
    if (arg.startsWith("--output=")) {
      args.outputPath = path.resolve(rootDir, arg.slice("--output=".length));
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

async function loadConfig() {
  const raw = await readFile(configPath, "utf8");
  return JSON.parse(raw);
}

function getRojoBinary() {
  const localRojo = path.join(rootDir, ".tools", "rojo", "rojo");
  if (existsSync(localRojo)) return localRojo;
  return "rojo";
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: rootDir,
      stdio: "inherit"
    });

    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${path.basename(command)} exited with code ${code}`));
      }
    });
  });
}

function requireApiKey() {
  const apiKey = process.env.ROBLOX_API_KEY;
  if (!apiKey) {
    throw new Error("ROBLOX_API_KEY is missing. Add it to .env before publishing.");
  }
  return apiKey;
}

async function buildPlace(outputPath) {
  await mkdir(path.dirname(outputPath), { recursive: true });
  await run(getRojoBinary(), ["build", projectPath, "-o", outputPath]);
  console.log(`Built place file: ${outputPath}`);
}

async function publishPlace(outputPath, versionType) {
  const config = await loadConfig();
  const universeId = String(config.universeId || "").trim();
  const placeId = String(config.placeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");
  if (!placeId) throw new Error("metadata/roblox-metadata.json must include placeId.");
  if (!existsSync(outputPath)) throw new Error(`Place file does not exist: ${outputPath}`);

  const body = await readFile(outputPath);
  const url = `https://apis.roblox.com/universes/v1/${universeId}/places/${placeId}/versions?versionType=${encodeURIComponent(versionType)}`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "x-api-key": requireApiKey(),
      "content-type": "application/octet-stream"
    },
    body
  });

  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json") ? await response.json() : await response.text();
  if (!response.ok) {
    const details = typeof payload === "string" ? payload : JSON.stringify(payload, null, 2);
    throw new Error(`Roblox publish failed (${response.status}): ${details}`);
  }

  const versionNumber = typeof payload === "object" && payload ? payload.versionNumber : null;
  console.log(`Published place ${placeId} in universe ${universeId}.`);
  if (versionNumber) {
    console.log(`Roblox version number: ${versionNumber}`);
  }
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

loadDotEnv(envPath);

const args = parseArgs(process.argv.slice(2));
try {
  if (args.command === "build") {
    await buildPlace(args.outputPath);
  } else if (args.command === "publish") {
    await publishPlace(args.outputPath, args.versionType);
  } else if (args.command === "deploy") {
    await buildPlace(args.outputPath);
    await publishPlace(args.outputPath, args.versionType);
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
