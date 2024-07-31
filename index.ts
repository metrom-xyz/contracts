import { type ChainContract } from "viem";

export enum Environment {
    Development = "development",
    Staging = "staging",
}

export enum SupportedChain {
    Holesky = 17000,
    CeloAlfajores = 44787,
    MantleSepolia = 5003,
}

export const ADDRESS: Record<
    Environment,
    Record<SupportedChain, ChainContract>
> = {
    [Environment.Development]: {
        [SupportedChain.Holesky]: {
            address: "0xBB7a0d06c6f37B1607bceeaFA452216BC843C193",
            blockCreated: 2039209,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x766faa004398d68Ef7f64926525E7ad2933A0f87",
            blockCreated: 25404664,
        },
        [SupportedChain.MantleSepolia]: {
            address: "0x080a71eC6Cb5C67480DE006A59d7991cD8fD2329",
            blockCreated: 10444146,
        },
    },
    [Environment.Staging]: {
        [SupportedChain.Holesky]: {
            address: "0x44d112ACD0764960667a7b9eA95B8120f39f58C4",
            blockCreated: 2039220,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x52015b596e765F7AA2668BCC30Fc715748A20A8e",
            blockCreated: 25404677,
        },
        [SupportedChain.MantleSepolia]: {
            address: "0x87d24272071593B4a7907fd133E74EC30025D4F9",
            blockCreated: 10444197,
        },
    },
};
