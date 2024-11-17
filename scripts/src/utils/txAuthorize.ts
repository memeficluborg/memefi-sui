import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import { airdrop } from "../types/0x7f7a37c826c88bcfe9aecc042453395ddfa9df6f29cb7c97590bf86cf2b0a75e";
import { getDefaultAdminSignerKeypair } from "../helpers/getSigner";

export const authorizeApiRole = async (
  client: SuiClient,
  airdrop_registry: string,
  publisher_id: string,
  targetAddress: string
) => {
  const tx = new Transaction();

  airdrop.builder.authorizeApi(tx, [
    tx.object(airdrop_registry),
    tx.object(publisher_id),
    tx.pure.address(targetAddress),
  ]);

  // === Execute the transaction and get the effects ===
  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: getDefaultAdminSignerKeypair(),
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  // === Run the transaction in dev-inspect mode without executing it ===
  // const result = await client.devInspectTransactionBlock({
  //   transactionBlock: tx,
  //   sender: getDefaultAdminSignerKeypair().getPublicKey().toSuiAddress(),
  // });

  console.log("Authorization transaction result:", result);
  return result;
};
