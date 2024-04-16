import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export interface MetromContracts {
    factory: ChainContract;
    batchUpdater: ChainContract;
}

export const ADDRESSES: Record<SupportedChain, MetromContracts> = {
    [SupportedChain.CeloAlfajores]: {
        factory: {
            address: "0xb4F8FB8cC48A9Eb8d8E0A530C9775eD06728BaDd",
            blockCreated: 23576703,
        },
        batchUpdater: {
            address: "0xcA9b84f307c7E7825C6e9B1da732f0a7e953889D",
            blockCreated: 23576703,
        },
    },
};
