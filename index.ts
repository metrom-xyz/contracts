import type { ChainContract } from "viem";
import { celoAlfajores } from "viem/chains";

export const ADDRESS: Record<number, ChainContract> = {
    [celoAlfajores.id]: {
        address: "0xe82c4D8b993D613a28600B953e91A3A93Ae69Fd6",
        blockCreated: 23_111_863,
    },
};
