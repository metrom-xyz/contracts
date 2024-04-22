import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0x8F140C6473ab59adCe2a294EdE8d6aB485CfCb8c",
        blockCreated: 23_681_808,
    },
};
