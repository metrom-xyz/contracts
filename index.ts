import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0x8d98758EfF88Dc944035B0618a8412C400E71C72",
        blockCreated: 1561518,
    },
};
