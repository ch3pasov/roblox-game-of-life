#!/usr/bin/env node

import process from "node:process";
import {
  ensureDonationProduct,
  getDeveloperProduct,
  listDeveloperProducts,
  loadDotEnv,
  loadRobloxConfig
} from "./lib/roblox-open-cloud.mjs";

const DONATION_PRODUCT_ID = 3598443222;
const DONATION_PRODUCT_NAME = "Open Life Grid for Everyone";
const DONATION_PRODUCT_DESCRIPTION = "Support the goal to open Life Grid for everyone. At 1000 Robux donated, the release fee will be covered.";
const DONATION_PRODUCT_PRICE = 1000;

function usage() {
  console.log("Usage:");
  console.log("  node scripts/roblox-donation-product.mjs list");
  console.log("  node scripts/roblox-donation-product.mjs get");
  console.log("  node scripts/roblox-donation-product.mjs ensure");
}

function printProduct(product) {
  console.log(JSON.stringify({
    productId: product.productId,
    name: product.name,
    isForSale: product.isForSale,
    priceInformation: product.priceInformation
  }, null, 2));
}

loadDotEnv();

const command = process.argv[2];
try {
  const config = await loadRobloxConfig();
  const universeId = String(config.universeId || "").trim();
  if (!universeId) throw new Error("metadata/roblox-metadata.json must include universeId.");

  if (command === "list") {
    const products = await listDeveloperProducts({ universeId });
    console.log(JSON.stringify(products.developerProducts ?? [], null, 2));
  } else if (command === "get") {
    printProduct(await getDeveloperProduct({ universeId, productId: DONATION_PRODUCT_ID }));
  } else if (command === "ensure") {
    printProduct(await ensureDonationProduct({
      universeId,
      productId: DONATION_PRODUCT_ID,
      name: DONATION_PRODUCT_NAME,
      description: DONATION_PRODUCT_DESCRIPTION,
      price: DONATION_PRODUCT_PRICE
    }));
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
