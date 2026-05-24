#!/usr/bin/env node

import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();
const configPath = path.join(rootDir, "metadata", "roblox-metadata.json");
const envPath = path.join(rootDir, ".env");

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

async function loadConfig() {
  const raw = await readFile(configPath, "utf8");
  return JSON.parse(raw);
}

function timestamp() {
  return new Date().toISOString().replace(/[:.]/g, "-");
}

function requireApiKey() {
  const apiKey = process.env.ROBLOX_API_KEY;
  if (!apiKey) {
    throw new Error("ROBLOX_API_KEY is missing. Create .env from .env.example and paste your Open Cloud API key.");
  }
  return apiKey;
}

function optionalApiHeaders() {
  const apiKey = process.env.ROBLOX_API_KEY;
  return apiKey ? { "x-api-key": apiKey } : null;
}

function apiHeaders(extra = {}) {
  return {
    "x-api-key": requireApiKey(),
    ...extra
  };
}

async function requestJson(label, url, options = {}) {
  let response;
  try {
    response = await fetch(url, options);
  } catch (error) {
    const reason = error.cause?.code || error.cause?.message || error.message;
    throw new Error(`${label} failed before reaching Roblox: ${reason}`);
  }

  const contentType = response.headers.get("content-type") ?? "";
  const body = contentType.includes("application/json") ? await response.json() : await response.text();

  if (!response.ok) {
    const details = typeof body === "string" ? body : JSON.stringify(body, null, 2);
    throw new Error(`${label} failed (${response.status}): ${details}`);
  }

  return body;
}

async function tryExport(label, url, outDir, fileName, options = {}) {
  if (options === null) {
    const message = "Skipped because ROBLOX_API_KEY is missing.";
    await writeFile(path.join(outDir, `${fileName}.skipped.txt`), `${message}\n`);
    return { label, ok: false, skipped: true, error: message };
  }

  try {
    const data = await requestJson(label, url, options);
    await writeFile(path.join(outDir, fileName), JSON.stringify(data, null, 2) + "\n");
    return { label, ok: true, fileName };
  } catch (error) {
    await writeFile(path.join(outDir, `${fileName}.error.txt`), `${error.message}\n`);
    return { label, ok: false, error: error.message };
  }
}

async function exportMetadata() {
  const config = await loadConfig();
  const universeId = String(config.universeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");

  const outDir = path.join(rootDir, "metadata", "exported", timestamp());
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, "source-config.json"), JSON.stringify(config, null, 2) + "\n");

  const optionalAuthHeaders = optionalApiHeaders();
  const auth = optionalAuthHeaders ? { headers: optionalAuthHeaders } : null;
  const exports = [
    tryExport("Open Cloud universe", `https://apis.roblox.com/cloud/v2/universes/${universeId}`, outDir, "open-cloud-universe.json", auth),
    tryExport("Public game details", `https://games.roblox.com/v1/games?universeIds=${universeId}`, outDir, "public-game-details.json"),
    tryExport("Public game media", `https://games.roblox.com/v1/games/${universeId}/media`, outDir, "public-game-media.json"),
    tryExport("Public game media legacy", `https://games.roblox.com/v2/games/${universeId}/media`, outDir, "public-game-media-v2.json"),
    tryExport("Universe places", `https://develop.roblox.com/v1/universes/${universeId}/places`, outDir, "places.json"),
    tryExport("Game icons", `https://apis.roblox.com/legacy-game-internationalization/v1/game-icon/games/${universeId}`, outDir, "game-icons.json", auth),
    tryExport("Supported languages", `https://apis.roblox.com/legacy-game-internationalization/v1/supported-languages/games/${universeId}`, outDir, "supported-languages.json", auth),
    tryExport("Automatic translation status", `https://apis.roblox.com/legacy-game-internationalization/v1/supported-languages/games/${universeId}/automatic-translation-status`, outDir, "automatic-translation-status.json", auth)
  ];

  const results = await Promise.all(exports);
  await writeFile(path.join(outDir, "manifest.json"), JSON.stringify({ universeId, exportedAt: new Date().toISOString(), results }, null, 2) + "\n");
  console.log(`Exported metadata snapshot to ${outDir}`);
  for (const result of results) {
    console.log(`${result.ok ? "OK" : "WARN"} ${result.label}`);
  }
}

function absoluteAssetPath(assetPath) {
  return path.isAbsolute(assetPath) ? assetPath : path.join(rootDir, assetPath);
}

async function uploadImage(label, url, filePath) {
  const fullPath = absoluteAssetPath(filePath);
  if (!existsSync(fullPath)) throw new Error(`${label} file does not exist: ${fullPath}`);

  const form = new FormData();
  const bytes = await readFile(fullPath);
  const file = new Blob([bytes]);
  form.append("file", file, path.basename(fullPath));

  return requestJson(label, url, {
    method: "POST",
    headers: apiHeaders(),
    body: form
  });
}

async function updateDisplayInfo(config) {
  const placeId = String(config.placeId || "").trim();
  const displayName = String(config.displayName || "").trim();
  const description = String(config.description || "").trim();
  if (!displayName && !description) return false;
  if (!placeId) throw new Error("placeId is required before updating displayName or description. Run export and copy the root place ID into metadata/roblox-metadata.json.");

  const updateMask = [
    displayName ? "displayName" : "",
    description ? "description" : ""
  ].filter(Boolean).join(",");

  const payload = {};
  if (displayName) payload.displayName = displayName;
  if (description) payload.description = description;

  await requestJson("Update place display info", `https://apis.roblox.com/cloud/v2/universes/${config.universeId}/places/${placeId}?updateMask=${encodeURIComponent(updateMask)}`, {
    method: "PATCH",
    headers: apiHeaders({ "content-type": "application/json" }),
    body: JSON.stringify(payload)
  });

  console.log("Updated display name/description.");
  return true;
}

async function updateIcon(config) {
  const iconPath = String(config.iconPath || "").trim();
  if (!iconPath) return false;
  const languageCode = String(config.languageCode || "en-us").trim();

  await uploadImage(
    "Update game icon",
    `https://apis.roblox.com/legacy-game-internationalization/v1/game-icon/games/${config.universeId}/language-codes/${languageCode}`,
    iconPath
  );

  console.log("Uploaded game icon.");
  return true;
}

async function uploadThumbnails(config) {
  const thumbnails = Array.isArray(config.thumbnails) ? config.thumbnails : [];
  if (thumbnails.length === 0) return false;
  const languageCode = String(config.languageCode || "en-us").trim();

  for (const thumbnail of thumbnails) {
    const imagePath = String(thumbnail.path || "").trim();
    if (!imagePath) continue;
    const upload = await uploadImage(
      "Upload game thumbnail",
      `https://apis.roblox.com/legacy-game-internationalization/v1/game-thumbnails/games/${config.universeId}/language-codes/${languageCode}/image`,
      imagePath
    );

    if (thumbnail.altText) {
      await requestJson("Update thumbnail alt text", `https://apis.roblox.com/legacy-game-internationalization/v1/game-thumbnails/games/${config.universeId}/language-codes/${languageCode}/alt-text`, {
        method: "POST",
        headers: apiHeaders({ "content-type": "application/json" }),
        body: JSON.stringify({
          imageId: upload.imageId ?? upload.id,
          altText: thumbnail.altText
        })
      });
    }
  }

  console.log("Uploaded game thumbnails.");
  return true;
}

async function applyMetadata() {
  const config = await loadConfig();
  if (!String(config.universeId || "").trim()) throw new Error("metadata/roblox-metadata.json must include universeId.");

  console.log("Creating backup export before applying changes...");
  await exportMetadata();

  const changed = [
    await updateDisplayInfo(config),
    await updateIcon(config),
    await uploadThumbnails(config)
  ].some(Boolean);

  if (!changed) {
    console.log("No filled metadata fields to update.");
  }
}

function usage() {
  console.log("Usage:");
  console.log("  node scripts/roblox-metadata.mjs export");
  console.log("  node scripts/roblox-metadata.mjs apply");
}

loadDotEnv(envPath);

const command = process.argv[2];
try {
  if (command === "export") {
    await exportMetadata();
  } else if (command === "apply") {
    await applyMetadata();
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
