import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0xDD15Dc3D5Ae4Dc6c59F1461d1b6233cf88b2a871",
        blockCreated: 23693186,
    },
};
