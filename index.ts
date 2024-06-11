import type { ChainContract } from "viem";
import { holesky, celoAlfajores } from "viem/chains";

export enum SupportedChain {
    Holesky = holesky.id,
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0xd1c1153fd809Aae3bb431b586C032C4856abaeD4",
        blockCreated: 1715203,
    },
    [SupportedChain.CeloAlfajores]: {
        address: "0xDDD3e99f11488290Ff07BAe128Bd6D23362f2455",
        blockCreated: 24543646,
    },
};
