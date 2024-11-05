import { authorizeApiRole } from "./utils/txAuthorize";
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  PUBLISHER_ID,
  API_ADDRESS,
} from "./config";

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

// Example transaction digest: J7zdDUnZrcNVt9UqaTdze1u7Sgj2LAREdPgkbnrhPB2T
