import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESSES: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0x97fdbf49e4C5649477e4f2f26cCE772bEa4e6165",
        blockCreated: 23_681_326,
    },
};
