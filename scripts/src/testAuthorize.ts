import { authorizeApiRole } from "./utils/txAuthorize";
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  PUBLISHER_ID,
  API_ADDRESS,
} from "./config";
import { _0x2 } from "@typemove/sui/builtin";

async function main() {
  try {
    await authorizeApiRole(
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
