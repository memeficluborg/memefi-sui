import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import { safe } from "../types/0x7f7a37c826c88bcfe9aecc042453395ddfa9df6f29cb7c97590bf86cf2b0a75e";
import { getDefaultAdminSignerKeypair } from "../helpers/getSigner";
import { MEMEFI_COIN_TYPE } from "../config";

const ONE_MEMEFI = 1_000_000_000; // 1 token * 10^9 decimals

export const deposit = async (
  client: SuiClient,
  safe_id: string,
  coin_id: string,
  publisher_id: string
) => {
  const tx = new Transaction();

  // Create a new coin object from the coin_id with the balance we want to deposit.
  const [coin_to_deposit] = tx.splitCoins(tx.object(coin_id), [ONE_MEMEFI]);
  coin_to_deposit["kind"] = "Input";

  safe.builder.put(
    tx,
    [tx.object(safe_id), coin_to_deposit, tx.object(publisher_id)],
    [MEMEFI_COIN_TYPE]
  );

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

  console.log("Transaction result:", result);
  return result;
};

export const withdrawAll = async (
  client: SuiClient,
  safe_id: string,
  publisher_id: string
) => {
  const tx = new Transaction();

  const [coin_to_withdraw] = safe.builder.withdraw(
    tx,
    [tx.object(safe_id), tx.object(publisher_id)],
    [MEMEFI_COIN_TYPE]
  );

  tx.transferObjects(
    [coin_to_withdraw],
    getDefaultAdminSignerKeypair().toSuiAddress()
  );

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

  console.log("Transaction result:", result);
  return result;
};
