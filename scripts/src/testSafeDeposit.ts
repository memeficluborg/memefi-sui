import { deposit } from "./utils/txSafe";
import {
  suiClient,
  SHARED_SAFE,
  PUBLISHER_ID,
  MEMEFI_COIN_TYPE,
} from "./config";
import { getDefaultAdminSignerKeypair } from "./helpers/getSigner";
import { getAllCoins } from "./helpers/getCoins";

async function main() {
  try {
    // Query for all `MEMEFI` coins under the sender's address.
    const memefi_coins = await getAllCoins(
      suiClient,
      getDefaultAdminSignerKeypair().getPublicKey().toSuiAddress(),
      MEMEFI_COIN_TYPE
    );

    // Pass the first coin to the deposit function.
    const coin_id = memefi_coins[0].coinObjectId;
    await deposit(suiClient, SHARED_SAFE, coin_id, PUBLISHER_ID);
  } catch (error) {
    console.error("Deposit to Safe failed:", error);
  }
}

main();
