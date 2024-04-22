import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0x613e4da8b515D11908b1024189564674CA376615",
        blockCreated: 23682093,
    },
};
