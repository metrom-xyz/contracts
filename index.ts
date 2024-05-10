import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0xDD15Dc3D5Ae4Dc6c59F1461d1b6233cf88b2a871",
        blockCreated: 1516321,
    },
};
