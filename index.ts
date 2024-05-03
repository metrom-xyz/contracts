import type { ChainContract } from "viem";
import { celoAlfajores, sepolia, holesky } from "viem/chains";

export enum SupportedChain {
    CeloAlfajores = celoAlfajores.id,
    Sepolia = sepolia.id,
    Holesky = holesky.id,
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
    [SupportedChain.Holesky]: {
        address: "0x64a0745EF9d3772d9739D9350873eD3703bE45eC",
        blockCreated: 1468875,
    },
};
