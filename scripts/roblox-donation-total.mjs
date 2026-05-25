#!/usr/bin/env node

import process from "node:process";
import {
  getDataStoreEntry,
  loadDotEnv,
  loadRobloxConfig
} from "./lib/roblox-open-cloud.mjs";

loadDotEnv();

try {
  const config = await loadRobloxConfig();
  const universeId = String(config.universeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");

  const total = await getDataStoreEntry({
    universeId,
    datastoreName: "LifeGridDonations",
    entryKey: "DonationTotalRobux"
  });

  console.log(JSON.stringify({ totalRobux: total }, null, 2));
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
