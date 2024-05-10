import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0xA310dee8A01880977Ba24d39e58049AE02F77EC3",
        blockCreated: 1516415,
    },
};
