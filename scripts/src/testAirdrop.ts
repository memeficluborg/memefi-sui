import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  SHARED_SAFE,
  API_ADDRESS,
  MEMEFI_COIN_TYPE,
} from "./config";
import { airdrop } from "./types/0x7f7a37c826c88bcfe9aecc042453395ddfa9df6f29cb7c97590bf86cf2b0a75e";
import { getDefaultAdminSignerKeypair } from "./helpers/getSigner";

interface Airdrop {
  client: SuiClient; // SuiClient instance
  registryId: string; // AirdropRegistry shared object
  safeId: string; // Safe shared object
  value: number; // Token value to airdrop
  userAddress: string; // User address to airdrop
  userTelegramId: string; // User Telegram ID
}

const EXAMPLE_AIRDROP_AMOUNT = 1_000_000_000; // 1 token * 10^9 decimals
const EXAMPLE_USER_ADDRESS = API_ADDRESS;
const EXAMPLE_USER_TELEGRAM_ID = "1234567891";
const ONE_MEMEFI = 1_000_000_000; // 1 token * 10^9 decimals

async function testAirdrop({
  client,
  registryId,
  safeId,
  value,
  userAddress,
  userTelegramId,
}: Airdrop) {
  // Airdrop Prerequisites:
  // 1. The sender (e.g. backend) must be authorized with `ApiRole` in the `AirdropRegistry`.
  // 2. The `Publisher` must have deposited enough amount of `MEMEFI` tokens in the `Safe`.
  // 3. The `Safe` must have enough tokens to airdrop to the user.
  try {
    const tx = new Transaction();

    // Step 1: Initialize the airdrop
    let [airdrop_config] = airdrop.builder.initSend(tx, [registryId]);

    // Step 2: Airdrop a specific amount of tokens to a specific address
    airdrop.builder.sendToken(
      tx,
      [
        tx.object(safeId),
        tx.pure.u64(BigInt(value)),
        userTelegramId,
        tx.pure.address(userAddress),
        tx.object(registryId),
        airdrop_config,
      ],
      [MEMEFI_COIN_TYPE]
    );

    // Step 3: Finalize the airdrop and resolve the `airdrop_config` hot-potato.
    airdrop.builder.finalizeSend(tx, [registryId, airdrop_config]);

    // === Execute the transaction and get the effects ===
    const response = await client.signAndExecuteTransaction({
      transaction: tx,
      signer: getDefaultAdminSignerKeypair(),
      options: {
        showEffects: true,
        showObjectChanges: true,
      },
    });

    // === Run the transaction in dev-inspect mode without executing it ===
    // const response = await client.devInspectTransactionBlock({
    //   transactionBlock: tx,
    //   sender: getDefaultAdminSignerKeypair().getPublicKey().toSuiAddress(),
    // });

    console.log("Airdrop Transaction Response:", response);
  } catch (error) {
    console.error("Error executing airdrop:", error);
  }
}

// Execute the airdrop with example values
testAirdrop({
  client: suiClient,
  registryId: SHARED_AIRDROP_REGISTRY,
  safeId: SHARED_SAFE,
  value: EXAMPLE_AIRDROP_AMOUNT,
  userAddress: EXAMPLE_USER_ADDRESS,
  userTelegramId: EXAMPLE_USER_TELEGRAM_ID,
});

// Example transaction digest: FbBJGN47kuChh48jCeuxirHVxCheVTCm4WbKqocVj5zT
