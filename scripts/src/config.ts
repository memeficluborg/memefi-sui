import { config } from "dotenv";
import { SuiClient } from "@mysten/sui/client";
import { defaultMoveCoder, MoveCoder } from "@typemove/sui";

config({});

type NetworkEnvironment = "devnet" | "testnet" | "mainnet";

export const SUI_NETWORK = process.env.SUI_NETWORK!;
export const ACTIVE_NETWORK = (process.env.SUI_ENV ??
  "devnet") as NetworkEnvironment;
export const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS!;
export const API_ADDRESS = process.env.API_ADDRESS!;
export const ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY!;

export const PACKAGE_ID = process.env.PACKAGE_ID!;
export const PUBLISHER_ID = process.env.PUBLISHER_ID!;
export const SHARED_AIRDROP_REGISTRY = process.env.SHARED_AIRDROP_REGISTRY!;
export const SHARED_WRAPPED_TREASURY = process.env.SHARED_WRAPPED_TREASURY!;
export const SHARED_SAFE = process.env.SHARED_SAFE!;
export const MEMEFI_COIN_TYPE = `${PACKAGE_ID}::memefi::MEMEFI`;

export const suiClient = new SuiClient({
  url: SUI_NETWORK,
});

const moveCoder = new MoveCoder(suiClient);

export async function initCoder(): Promise<MoveCoder> {
  return moveCoder;
}

export default moveCoder;
