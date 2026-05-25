#!/usr/bin/env node

import process from "node:process";
import {
  ensureDonationProduct,
  getDeveloperProduct,
  listDeveloperProducts,
  loadDotEnv,
  loadRobloxConfig
} from "./lib/roblox-open-cloud.mjs";

const DONATION_PRODUCTS = [
  { productId: 3598501584, price: 10 },
  { productId: 3598501592, price: 50 },
  { productId: 3598501597, price: 100 },
  { productId: 3598501604, price: 250 },
  { productId: 3598443222, price: 1000 }
];

function productName(price) {
  return `Life Grid donation ${price} Robux`;
}

function productDescription(price) {
  return `Donate ${price} Robux toward opening Life Grid for everyone. At 1000 Robux donated, the release fee will be covered.`;
}

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
    for (const product of DONATION_PRODUCTS.filter((item) => item.productId)) {
      printProduct(await getDeveloperProduct({ universeId, productId: product.productId }));
    }
  } else if (command === "ensure") {
    const ensured = [];
    for (const product of DONATION_PRODUCTS) {
      ensured.push(await ensureDonationProduct({
        universeId,
        productId: product.productId,
        name: productName(product.price),
        description: productDescription(product.price),
        price: product.price
      }));
    }

    for (const product of ensured) {
      printProduct(product);
    }
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
