import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0xc9CC9a4d4F2c57F0d47c169A3d96D47FfFe5E0b6",
        blockCreated: 1536780,
    },
};
