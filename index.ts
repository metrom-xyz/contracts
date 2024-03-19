import type { ChainContract } from "viem";
import { sepolia } from "viem/chains";

export enum ChainId {
    Sepolia = sepolia.id,
}

export const DEPLOYMENT_ADDRESSES: Record<ChainId, ChainContract> = {
    [ChainId.Sepolia]: {
        address: "0xB725486e93926101E2E629b6790D27A4729920E5",
        blockCreated: 4_518_508,
    },
};
