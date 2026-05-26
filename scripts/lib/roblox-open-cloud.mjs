import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync, readFileSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";

export const DEFAULT_PLACE_OUTPUT = path.join(process.cwd(), "build", "game-of-life.rbxl");

export function loadDotEnv(filePath = path.join(process.cwd(), ".env")) {
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

export async function loadRobloxConfig(configPath = path.join(process.cwd(), "metadata", "roblox-metadata.json")) {
  const raw = await readFile(configPath, "utf8");
  return JSON.parse(raw);
}

export function requireApiKey() {
  const apiKey = process.env.ROBLOX_API_KEY;
  if (!apiKey) {
    throw new Error("ROBLOX_API_KEY is missing. Create .env from .env.example and paste your Open Cloud API key.");
  }
  return apiKey;
}

export function optionalApiHeaders() {
  const apiKey = process.env.ROBLOX_API_KEY;
  return apiKey ? { "x-api-key": apiKey } : null;
}

export function apiHeaders(extra = {}) {
  return {
    "x-api-key": requireApiKey(),
    ...extra
  };
}

export async function robloxRequest(label, url, options = {}) {
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

function timestamp() {
  return new Date().toISOString().replace(/[:.]/g, "-");
}

async function tryExport(label, url, outDir, fileName, options = {}) {
  if (options === null) {
    const message = "Skipped because ROBLOX_API_KEY is missing.";
    await writeFile(path.join(outDir, `${fileName}.skipped.txt`), `${message}\n`);
    return { label, ok: false, skipped: true, error: message };
  }

  try {
    const data = await robloxRequest(label, url, options);
    await writeFile(path.join(outDir, fileName), JSON.stringify(data, null, 2) + "\n");
    return { label, ok: true, fileName };
  } catch (error) {
    await writeFile(path.join(outDir, `${fileName}.error.txt`), `${error.message}\n`);
    return { label, ok: false, error: error.message };
  }
}

export async function exportMetadata({ rootDir = process.cwd(), config = null } = {}) {
  const metadata = config ?? await loadRobloxConfig(path.join(rootDir, "metadata", "roblox-metadata.json"));
  const universeId = String(metadata.universeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");

  const outDir = path.join(rootDir, "metadata", "exported", timestamp());
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, "source-config.json"), JSON.stringify(metadata, null, 2) + "\n");

  const optionalAuthHeaders = optionalApiHeaders();
  const auth = optionalAuthHeaders ? { headers: optionalAuthHeaders } : null;
  const exports = [
    tryExport("Open Cloud universe", `https://apis.roblox.com/cloud/v2/universes/${universeId}`, outDir, "open-cloud-universe.json", auth),
    metadata.placeId
      ? tryExport("Open Cloud root place", `https://apis.roblox.com/cloud/v2/universes/${universeId}/places/${metadata.placeId}`, outDir, "open-cloud-root-place.json", auth)
      : Promise.resolve({ label: "Open Cloud root place", ok: false, skipped: true, error: "Skipped because placeId is missing." }),
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
  return { outDir, results };
}

function absoluteAssetPath(rootDir, assetPath) {
  return path.isAbsolute(assetPath) ? assetPath : path.join(rootDir, assetPath);
}

export async function uploadImage({ label, url, filePath, rootDir = process.cwd() }) {
  const fullPath = absoluteAssetPath(rootDir, filePath);
  if (!existsSync(fullPath)) throw new Error(`${label} file does not exist: ${fullPath}`);

  const form = new FormData();
  const bytes = await readFile(fullPath);
  const file = new Blob([bytes]);
  form.append("file", file, path.basename(fullPath));

  return robloxRequest(label, url, {
    method: "POST",
    headers: apiHeaders(),
    body: form
  });
}

export async function updatePlaceDisplayInfo(config) {
  const placeId = String(config.placeId || "").trim();
  const displayName = String(config.displayName || "").trim();
  const description = String(config.description || "").trim();
  if (!displayName && !description) return false;
  if (!placeId) throw new Error("placeId is required before updating displayName or description.");

  const updateMask = [
    displayName ? "displayName" : "",
    description ? "description" : ""
  ].filter(Boolean).join(",");

  const payload = {};
  if (displayName) payload.displayName = displayName;
  if (description) payload.description = description;

  await robloxRequest("Update place display info", `https://apis.roblox.com/cloud/v2/universes/${config.universeId}/places/${placeId}?updateMask=${encodeURIComponent(updateMask)}`, {
    method: "PATCH",
    headers: apiHeaders({ "content-type": "application/json" }),
    body: JSON.stringify(payload)
  });

  return true;
}

export async function updateGameIcon(config, { rootDir = process.cwd() } = {}) {
  const iconPath = String(config.iconPath || "").trim();
  if (!iconPath) return false;
  const languageCode = String(config.languageCode || "en-us").trim();

  await uploadImage({
    label: "Update game icon",
    url: `https://apis.roblox.com/legacy-game-internationalization/v1/game-icon/games/${config.universeId}/language-codes/${languageCode}`,
    filePath: iconPath,
    rootDir
  });

  return true;
}

export async function uploadGameThumbnails(config, { rootDir = process.cwd() } = {}) {
  const thumbnails = Array.isArray(config.thumbnails) ? config.thumbnails : [];
  if (thumbnails.length === 0) return false;
  const languageCode = String(config.languageCode || "en-us").trim();

  for (const thumbnail of thumbnails) {
    const imagePath = String(thumbnail.path || "").trim();
    if (!imagePath) continue;
    const upload = await uploadImage({
      label: "Upload game thumbnail",
      url: `https://apis.roblox.com/legacy-game-internationalization/v1/game-thumbnails/games/${config.universeId}/language-codes/${languageCode}/image`,
      filePath: imagePath,
      rootDir
    });

    if (thumbnail.altText) {
      await robloxRequest("Update thumbnail alt text", `https://apis.roblox.com/legacy-game-internationalization/v1/game-thumbnails/games/${config.universeId}/language-codes/${languageCode}/alt-text`, {
        method: "POST",
        headers: apiHeaders({ "content-type": "application/json" }),
        body: JSON.stringify({
          imageId: upload.imageId ?? upload.id,
          altText: thumbnail.altText
        })
      });
    }
  }

  return true;
}

function filledKeys(payload) {
  return Object.entries(payload)
    .filter(([, value]) => value !== undefined)
    .map(([key]) => key);
}

function socialLinkPayload(value) {
  if (value === undefined) return undefined;
  if (value === null) return undefined;
  if (typeof value === "string") {
    const uri = value.trim();
    return uri ? { title: "", uri } : undefined;
  }
  if (typeof value === "object") {
    const title = String(value.title ?? "").trim();
    const uri = String(value.uri ?? value.url ?? "").trim();
    return uri ? { title, uri } : undefined;
  }
  return undefined;
}

export async function updateUniverseExperienceSettings(config) {
  const settings = config.experienceSettings ?? {};
  const universeId = String(config.universeId || "").trim();
  if (!universeId) throw new Error("universeId is required before updating experience settings.");

  const devices = settings.devices ?? {};
  const socialLinks = settings.socialLinks ?? {};
  const payload = {
    visibility: settings.visibility,
    voiceChatEnabled: settings.voiceChatEnabled,
    privateServerPriceRobux: settings.privateServerPriceRobux,
    desktopEnabled: devices.desktop,
    mobileEnabled: devices.mobile,
    tabletEnabled: devices.tablet,
    consoleEnabled: devices.console,
    vrEnabled: devices.vr,
    facebookSocialLink: socialLinkPayload(socialLinks.facebook),
    twitterSocialLink: socialLinkPayload(socialLinks.twitter),
    youtubeSocialLink: socialLinkPayload(socialLinks.youtube),
    twitchSocialLink: socialLinkPayload(socialLinks.twitch),
    discordSocialLink: socialLinkPayload(socialLinks.discord),
    robloxGroupSocialLink: socialLinkPayload(socialLinks.robloxGroup)
  };

  const updateMask = filledKeys(payload);
  if (updateMask.length === 0) return { changed: false, unsupported: [] };

  await robloxRequest("Update universe experience settings", `https://apis.roblox.com/cloud/v2/universes/${universeId}?updateMask=${encodeURIComponent(updateMask.join(","))}`, {
    method: "PATCH",
    headers: apiHeaders({ "content-type": "application/json" }),
    body: JSON.stringify(payload)
  });

  const unsupported = [];
  if (settings.dashboardOnly?.genre !== undefined) unsupported.push("experienceSettings.dashboardOnly.genre");
  if (settings.dashboardOnly?.cameraEnabled !== undefined) unsupported.push("experienceSettings.dashboardOnly.cameraEnabled");
  if (settings.dashboardOnly?.contentMaturity !== undefined) unsupported.push("experienceSettings.dashboardOnly.contentMaturity");

  return { changed: true, unsupported };
}

export async function updateRootPlaceExperienceSettings(config) {
  const placeSettings = config.experienceSettings?.place ?? {};
  const universeId = String(config.universeId || "").trim();
  const placeId = String(config.placeId || "").trim();
  if (!universeId) throw new Error("universeId is required before updating root place settings.");
  if (!placeId) throw new Error("placeId is required before updating root place settings.");

  const payload = {
    serverSize: placeSettings.serverSize
  };
  const updateMask = filledKeys(payload);
  if (updateMask.length === 0) return false;

  await robloxRequest("Update root place experience settings", `https://apis.roblox.com/cloud/v2/universes/${universeId}/places/${placeId}?updateMask=${encodeURIComponent(updateMask.join(","))}`, {
    method: "PATCH",
    headers: apiHeaders({ "content-type": "application/json" }),
    body: JSON.stringify(payload)
  });

  return true;
}

export async function applyMetadata({ rootDir = process.cwd() } = {}) {
  const config = await loadRobloxConfig(path.join(rootDir, "metadata", "roblox-metadata.json"));
  if (!String(config.universeId || "").trim()) throw new Error("metadata/roblox-metadata.json must include universeId.");

  const backup = await exportMetadata({ rootDir, config });
  const universeSettings = await updateUniverseExperienceSettings(config);
  const changes = {
    displayInfo: await updatePlaceDisplayInfo(config),
    icon: await updateGameIcon(config, { rootDir }),
    thumbnails: await uploadGameThumbnails(config, { rootDir }),
    universeSettings: universeSettings.changed,
    rootPlaceSettings: await updateRootPlaceExperienceSettings(config)
  };

  return {
    backup,
    changes,
    unsupported: universeSettings.unsupported,
    changed: Object.values(changes).some(Boolean)
  };
}

function getRojoBinary(rootDir) {
  const localRojo = path.join(rootDir, ".tools", "rojo", "rojo");
  if (existsSync(localRojo)) return localRojo;
  return "rojo";
}

function run(command, args, { cwd = process.cwd() } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
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

export async function buildPlace({ rootDir = process.cwd(), projectPath = path.join(rootDir, "default.project.json"), outputPath = DEFAULT_PLACE_OUTPUT } = {}) {
  await mkdir(path.dirname(outputPath), { recursive: true });
  await run(getRojoBinary(rootDir), ["build", projectPath, "-o", outputPath], { cwd: rootDir });
  return outputPath;
}

export async function publishPlace({ rootDir = process.cwd(), outputPath = DEFAULT_PLACE_OUTPUT, versionType = "Published" } = {}) {
  const config = await loadRobloxConfig(path.join(rootDir, "metadata", "roblox-metadata.json"));
  const universeId = String(config.universeId || "").trim();
  const placeId = String(config.placeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");
  if (!placeId) throw new Error("metadata/roblox-metadata.json must include placeId.");
  if (!existsSync(outputPath)) throw new Error(`Place file does not exist: ${outputPath}`);

  const body = await readFile(outputPath);
  return robloxRequest("Publish place", `https://apis.roblox.com/universes/v1/${universeId}/places/${placeId}/versions?versionType=${encodeURIComponent(versionType)}`, {
    method: "POST",
    headers: apiHeaders({ "content-type": "application/octet-stream" }),
    body
  });
}

export async function deployPlace(options = {}) {
  const outputPath = await buildPlace(options);
  const result = await publishPlace({ ...options, outputPath });
  return { outputPath, result };
}

export async function listDeveloperProducts({ universeId, pageSize = 50, pageToken = "" }) {
  const tokenQuery = pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : "";
  return robloxRequest("List developer products", `https://apis.roblox.com/developer-products/v2/universes/${universeId}/developer-products/creator?pageSize=${pageSize}${tokenQuery}`, {
    headers: apiHeaders()
  });
}

export async function getDeveloperProduct({ universeId, productId }) {
  return robloxRequest("Get developer product", `https://apis.roblox.com/developer-products/v2/universes/${universeId}/developer-products/${productId}/creator`, {
    headers: apiHeaders()
  });
}

function developerProductForm({ name, description, price, isForSale = null }) {
  const form = new FormData();
  form.append("Name", name);
  form.append("Description", description);
  if (price !== undefined && price !== null) {
    form.append("Price", String(price));
  }
  if (isForSale !== null) {
    form.append("IsForSale", String(isForSale));
  }
  return form;
}

export async function createDeveloperProduct({ universeId, name, description, price }) {
  return robloxRequest("Create developer product", `https://apis.roblox.com/developer-products/v2/universes/${universeId}/developer-products`, {
    method: "POST",
    headers: apiHeaders(),
    body: developerProductForm({ name, description, price })
  });
}

export async function updateDeveloperProduct({ universeId, productId, name, description, price, isForSale = null }) {
  return robloxRequest("Update developer product", `https://apis.roblox.com/developer-products/v2/universes/${universeId}/developer-products/${productId}`, {
    method: "PATCH",
    headers: apiHeaders(),
    body: developerProductForm({ name, description, price, isForSale })
  });
}

function developerProductPrice(product) {
  const info = product?.priceInformation ?? {};
  return info.defaultPriceInRobux ?? info.priceInRobux ?? info.price ?? null;
}

function developerProductMatches(product, { name, price }) {
  return product?.name === name
    && developerProductPrice(product) === price
    && product?.isForSale === true;
}

function isRateLimitError(error) {
  return /\(429\)/.test(error?.message ?? "");
}

export async function ensureDonationProduct({ universeId, productId = null, name, description, price }) {
  if (productId) {
    const existing = await getDeveloperProduct({ universeId, productId });
    if (developerProductMatches(existing, { name, price })) return existing;

    try {
      await updateDeveloperProduct({ universeId, productId, name, description, price, isForSale: true });
    } catch (error) {
      if (!isRateLimitError(error)) throw error;
      return existing;
    }

    return getDeveloperProduct({ universeId, productId });
  }

  const products = await listDeveloperProducts({ universeId });
  const existing = products.developerProducts?.find((product) => product.name === name);
  if (existing) {
    if (developerProductMatches(existing, { name, price })) return existing;
    try {
      await updateDeveloperProduct({ universeId, productId: existing.productId, name, description, price, isForSale: true });
    } catch (error) {
      if (!isRateLimitError(error)) throw error;
      return existing;
    }
    return getDeveloperProduct({ universeId, productId: existing.productId });
  }

  const created = await createDeveloperProduct({ universeId, name, description, price });
  await updateDeveloperProduct({ universeId, productId: created.productId, name, description, price, isForSale: true });
  return getDeveloperProduct({ universeId, productId: created.productId });
}

export async function getDataStoreEntry({ universeId, datastoreName, entryKey, scope = "global" }) {
  const search = new URLSearchParams({
    datastoreName,
    entryKey,
    scope
  });

  return robloxRequest("Get data store entry", `https://apis.roblox.com/datastores/v1/universes/${universeId}/standard-datastores/datastore/entries/entry?${search.toString()}`, {
    headers: apiHeaders()
  });
}
