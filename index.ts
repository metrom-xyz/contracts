import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0x5d0a4B3D99ED117E87570Bd1aeF89a972ff218E7",
        blockCreated: 1543251,
    },
};
