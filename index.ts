import type { ChainContract } from "viem";
import { holesky, celoAlfajores } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0x10E1A22034C5AF1E793c2Ac189b90ca47b252fF9",
        blockCreated: 1663871,
    },
    [SupportedChain.CeloAlfajores]: {
        address: "0x6DE23781114530cfE5606b1B8Ad5698696EdFf23",
        blockCreated: 24427676,
    },
};
