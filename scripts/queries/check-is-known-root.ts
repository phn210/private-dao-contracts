import { deploy } from "../deploy-with-check";

const root =
    18839682444875989663287299599924359730671459830010219777153572616452823568398n;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    let result = await _.FundManager.isKnownRoot(root);
    console.log(result);
}

main().then(() => {});
