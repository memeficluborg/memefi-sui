import { reserveGas, executeTransaction } from "./helpers/gasPool"; // Ensure this file exists as shown in previous steps
import {
  suiClient,
  SHARED_AIRDROP_REGISTRY,
  PUBLISHER_ID,
  API_ADDRESS,
} from "./config";
import { Transaction } from "@mysten/sui/transactions";
import { getDefaultAdminSignerKeypair } from "./helpers/getSigner";
import { airdrop } from "./types/0x7f7a37c826c88bcfe9aecc042453395ddfa9df6f29cb7c97590bf86cf2b0a75e";
import { toBase64 } from "@mysten/sui/utils";

async function main() {
  try {
    console.log("Starting authorization test with Gas Pool...");

    // === Step 1: Reserve Gas ===
    const gasBudget = 10_000_000; // Adjust this budget as needed
    const reserveDurationSecs = 300; // Reserve for 5 minutes
    console.log("Reserving gas...");

    const gasReservation = await reserveGas(gasBudget, reserveDurationSecs);
    console.log("Gas reserved:", gasReservation);

    if (!gasReservation.result) {
      throw new Error(`Gas reservation failed: ${gasReservation.error}`);
    }

    const reservationId = gasReservation.result.reservation_id;

    // === Step 2: Build the Transaction ===
    console.log("Building transaction...");
    const tx = new Transaction();

    // Add `authorizeApiRole` logic
    airdrop.builder.authorizeApi(tx, [
      tx.object(SHARED_AIRDROP_REGISTRY),
      tx.object(PUBLISHER_ID),
      tx.pure.address(API_ADDRESS),
    ]);

    tx.setSender(getDefaultAdminSignerKeypair().getPublicKey().toSuiAddress()); // Set sender
    tx.setGasPayment(gasReservation.result.gas_coins); // Use reserved gas coins
    tx.setGasOwner(gasReservation.result.sponsor_address); // Use gas owner

    // Serialize the transaction
    const txBytes = await tx.build({
      client: suiClient,
    });
    console.log("Transaction built:", txBytes);

    // === Step 3: Sign the Transaction ===
    console.log("Signing transaction...");
    const signer = getDefaultAdminSignerKeypair();
    const userSig = await signer.signTransaction(txBytes);
    console.log("Transaction signed.");

    // === Step 4: Execute the Transaction Using Gas Pool ===
    console.log("Executing transaction via Gas Pool...");
    const executeResponse = await executeTransaction(
      reservationId,
      toBase64(txBytes),
      userSig.signature
    );

    if (executeResponse.error) {
      throw new Error(`Transaction execution failed: ${executeResponse.error}`);
    }

    console.log("Transaction executed successfully:", executeResponse.effects);
  } catch (error) {
    console.error("Authorization with Gas Pool failed:", error);
  }
}

main();
