import type { ChainContract } from "viem";
import { sepolia } from "viem/chains";

export enum ChainId {
    Sepolia = sepolia.id,
}

export const DEPLOYMENT_ADDRESSES: Record<ChainId, ChainContract> = {
    [ChainId.Sepolia]: {
        address: "0x05D1bE53482783619C616220F689A3044340d574",
        blockCreated: 5_518_376,
    },
};
