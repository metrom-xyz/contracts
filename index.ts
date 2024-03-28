import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0x1776bE1f971CB0F758680aCFD2cc5121B474249E",
        blockCreated: 23250417,
    },
};
