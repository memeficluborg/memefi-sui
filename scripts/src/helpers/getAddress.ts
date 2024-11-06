import { getSignerKeypair } from "./getSigner";

export const getAddress = (secretKey: string) => {
  const signer = getSignerKeypair(secretKey);
  return signer.toSuiAddress();
};
