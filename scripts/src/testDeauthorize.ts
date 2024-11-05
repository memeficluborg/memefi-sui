import { deauthorizeApiRole } from "./utils/txDeauthorize";
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  PUBLISHER_ID,
  API_ADDRESS,
} from "./config";
import { _0x2 } from "@typemove/sui/builtin";

async function main() {
  try {
    await deauthorizeApiRole(
      suiClient,
      SHARED_AIRDROP_REGISTRY,
      PUBLISHER_ID,
      API_ADDRESS
    );
  } catch (error) {
    console.error("Authorization failed:", error);
  }
}

main();
