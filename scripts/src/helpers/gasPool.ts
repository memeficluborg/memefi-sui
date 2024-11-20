import axios from 'axios';

const GAS_POOL_URL = 'http://localhost:9527';
const AUTH_TOKEN = process.env.GAS_STATION_AUTH;

export const reserveGas = async (gasBudget: number, duration: number) => {
  const response = await axios.post(
    `${GAS_POOL_URL}/v1/reserve_gas`,
    {
      gas_budget: gasBudget,
      reserve_duration_secs: duration,
    },
    {
      headers: {
        Authorization: `Bearer ${AUTH_TOKEN}`,
      },
    }
  );
  return response.data;
};

export const executeTransaction = async (
  reservationId: string,
  txBytes: string,
  userSig: string
) => {
  const response = await axios.post(
    `${GAS_POOL_URL}/v1/execute_tx`,
    {
      reservation_id: reservationId,
      tx_bytes: txBytes,
      user_sig: userSig,
    },
    {
      headers: {
        Authorization: `Bearer ${AUTH_TOKEN}`,
      },
    }
  );
  return response.data;
};