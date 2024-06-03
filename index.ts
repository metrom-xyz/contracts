import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0x10E1A22034C5AF1E793c2Ac189b90ca47b252fF9",
        blockCreated: 1663871,
    },
};
