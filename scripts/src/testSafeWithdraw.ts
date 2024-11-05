import { withdrawAll } from "./utils/txSafe";
import { suiClient, SHARED_SAFE, PUBLISHER_ID } from "./config";

async function main() {
  try {
    await withdrawAll(suiClient, SHARED_SAFE, PUBLISHER_ID);
  } catch (error) {
    console.error("Withdraw from Safe failed:", error);
  }
}

main();
