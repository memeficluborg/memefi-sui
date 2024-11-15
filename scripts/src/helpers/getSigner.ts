import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { fromB64 } from "@mysten/sui/utils";
import { ADMIN_PRIVATE_KEY } from "../config";

export const getSignerKeypair = (secretKey: string) => {
  let privKeyArray = Uint8Array.from(Array.from(fromB64(secretKey)));
  const keypair = Ed25519Keypair.fromSecretKey(
    Uint8Array.from(privKeyArray).slice(1)
  );
  return keypair;
};

export const getDefaultAdminSignerKeypair = () => {
  return getSignerKeypair(ADMIN_PRIVATE_KEY);
};
