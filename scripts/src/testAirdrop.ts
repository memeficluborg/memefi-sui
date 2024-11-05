import { Transaction } from "@mysten/sui/transactions";
import { suiClient, SHARED_AIRDROP_REGISTRY } from "./config";
import { airdrop } from "./types/0x7f7a37c826c88bcfe9aecc042453395ddfa9df6f29cb7c97590bf86cf2b0a75e";
import { getDefaultAdminSignerKeypair } from "./helpers/getSigner";

async function testInitSend(airdropRegistryId: string) {
  try {
    const tx = new Transaction();

    airdrop.builder.initSend(tx, [airdropRegistryId]);

    const response = await suiClient.signAndExecuteTransaction({
      transaction: tx,
      signer: getDefaultAdminSignerKeypair(),
      options: {
        showEffects: true,
        showObjectChanges: true,
      },
    });

    console.log("Transaction Response:", response);
  } catch (error) {
    console.error("Error executing initSend:", error);
  }
}

testInitSend(SHARED_AIRDROP_REGISTRY);
