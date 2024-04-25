import type { ChainContract } from "viem";
import { celoAlfajores, sepolia } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
    Sepolia = sepolia.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.CeloAlfajores]: {
        address: "0x2A447682071e7B53c19e68Aab15986ddADE9b984",
        blockCreated: 23729240,
    },
    [SupportedChain.Sepolia]: {
        address: "0x4038F70453Bd0Ef6936163A79B036E393B2ac79f",
        blockCreated: 5773663,
    },
};
