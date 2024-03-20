import { execSync } from "node:child_process";
import {
    appendFileSync,
    mkdirSync,
    readFileSync,
    rmSync,
    writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

function getJsonAsTypescript(json) {
    if (json instanceof Array) {
        return `[${json.map(getJsonAsTypescript).join(", ")}]`;
    } else if (typeof json === "object" && json !== null) {
        const properties = Object.keys(json)
            .map((key) => `${key}: ${getJsonAsTypescript(json[key])}`)
            .join(", ");
        return `{ ${properties} }`;
    } else if (typeof json === "string") {
        return `"${json}"`;
    } else {
        return json;
    }
}

const CURRENT_DIR = dirname(fileURLToPath(import.meta.url));

console.log("Building contracts...");
execSync("forge build", { stdio: "inherit" });

console.log("Removing previous dist folder...");
rmSync(join(CURRENT_DIR, "./dist"), { recursive: true });

console.log("Building library...");
execSync("pnpm tsc", { stdio: "inherit" });

console.log("Bundling ABIs...");

const { abi: metromCampaignAbi } = JSON.parse(
    readFileSync(
        join(CURRENT_DIR, "./out/IMetromCampaign.sol/IMetromCampaign.json"),
    ),
);

const { abi: metromCampaignFactoryAbi } = JSON.parse(
    readFileSync(
        join(
            CURRENT_DIR,
            "./out/IMetromCampaignFactory.sol/IMetromCampaignFactory.json",
        ),
    ),
);

mkdirSync(join(CURRENT_DIR, "./dist/abis"));

writeFileSync(
    join(CURRENT_DIR, "./dist/abis/MetromCampaign.json"),
    JSON.stringify(metromCampaignAbi, undefined, 4),
);
appendFileSync(
    join(CURRENT_DIR, "./dist/index.js"),
    `export const metromCampaignAbi = ${getJsonAsTypescript(metromCampaignAbi)};\n`,
);
appendFileSync(
    join(CURRENT_DIR, "./dist/index.d.ts"),
    `export declare const metromCampaignAbi = ${getJsonAsTypescript(metromCampaignAbi)} as const\n`,
);

writeFileSync(
    join(CURRENT_DIR, "./dist/abis/MetromCampaignFactory.json"),
    JSON.stringify(metromCampaignFactoryAbi, undefined, 4),
);
appendFileSync(
    join(CURRENT_DIR, "./dist/index.js"),
    `export const metromCampaignFactoryAbi = ${getJsonAsTypescript(metromCampaignAbi)};\n`,
);
appendFileSync(
    join(CURRENT_DIR, "./dist/index.d.ts"),
    `export declare const metromCampaignFactoryAbi = ${getJsonAsTypescript(metromCampaignAbi)} as const;\n`,
);
