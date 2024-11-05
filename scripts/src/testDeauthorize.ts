import { deauthorizeApiRole } from "./utils/txDeauthorize";
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  PUBLISHER_ID,
  API_ADDRESS,
} from "./config";

async function main() {
  try {
    await deauthorizeApiRole(
      suiClient,
      SHARED_AIRDROP_REGISTRY,
      PUBLISHER_ID,
      API_ADDRESS
    );
  } catch (error) {
    console.error("Deauthorization failed:", error);
  }
}

main();