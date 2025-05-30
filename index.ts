import { type ChainContract } from "viem";

export enum SupportedChain {
    // testnets
    Holesky = 17000,
    // CeloAlfajores = 44_787,
    // MantleSepolia = 5_003,
    BaseSepolia = 84532,
    // FormTestnet = 132_902,
    Sepolia = 11155111,

    // mainnets
    Mode = 34443,
    Mantle = 5000,
    Base = 8453,
    Taiko = 167000,
    Scroll = 534352,
    Sonic = 146,
    // Arthera = 10_242,
    Form = 478,
    Gnosis = 100,
    Telos = 40,
    LightLinkPhoenix = 1890,
    Sei = 1329,
    Swell = 1923,
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Holesky]: {
        address: "0xE2461a09B782efF63a2B50964a6DA3C15dD2A51e",
        blockCreated: 2189164,
    },
    // [SupportedChain.CeloAlfajores]: {
    //     address: "0x0Fe5A93b63ACcf31679321dd0Daf341c037A1187",
    //     blockCreated: 25798782,
    // },
    // [SupportedChain.MantleSepolia]: {
    //     address: "0xB6044f769f519a634A5150645484b18d0C031ae8",
    //     blockCreated: 11430844,
    // },
    [SupportedChain.BaseSepolia]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 16130946,
    },
    // [SupportedChain.FormTestnet]: {
    //     address: "0xBbB06b25484AB9E23FEe8Ee321Af8e253ea7A76a",
    //     blockCreated: 14587762,
    // },
    [SupportedChain.Sepolia]: {
        address: "0x9A6b8fb563ddB0a10C2F330F2C73F3B6cFDf0581",
        blockCreated: 7483369,
    },
    [SupportedChain.Base]: {
        address: "0xD1D3Cf05Ef211C71056f0aF1a7FD1DF989E109c3",
        blockCreated: 20622498,
    },
    [SupportedChain.Mode]: {
        address: "0xc325890958D399ee26c26D21bBeFbDA17B03a611",
        blockCreated: 12904333,
    },
    [SupportedChain.Mantle]: {
        address: "0x4300d4C410f87c7c1824Cbc2eF67431030106604",
        blockCreated: 68933021,
    },
    [SupportedChain.Taiko]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 460190,
    },
    [SupportedChain.Scroll]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 10721351,
    },
    [SupportedChain.Sonic]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 693310,
    },
    // [SupportedChain.Arthera]: {
    //     address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
    //     blockCreated: 20052564,
    // },
    [SupportedChain.Form]: {
        address: "0xD6e88c910329fE3597498772eB94991a0630306d",
        blockCreated: 1238292,
    },
    [SupportedChain.Gnosis]: {
        address: "0x9430990117A7451e3d0a3d89796FC0b0c294Da9c",
        blockCreated: 38018174,
    },
    [SupportedChain.Telos]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 390899406,
    },
    [SupportedChain.LightLinkPhoenix]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 134711473,
    },
    [SupportedChain.Sei]: {
        address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
        blockCreated: 141494257,
    },
    [SupportedChain.Swell]: {
        address: "0x95Bf186929194099899139Ff79998cC147290F28",
        blockCreated: 7309091,
    },
};
