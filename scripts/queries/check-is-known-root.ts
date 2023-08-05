import { deploy } from "../deploy-with-check";

const root =
    10399602789488381211849145976571388105747490234315561341892992155201232816845n;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    let result = await _.FundManager.isKnownRoot(root);
    console.log(result);
}

main().then(() => {});
