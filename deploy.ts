import * as fs from "fs";
import {
  RpcProvider,
  Account,
  CallData,
  Calldata,
  Contract,
  json,
  RawCalldata,
  CompiledSierra
} from "starknet";

// load environment variables
require("dotenv").config();

const rpcUrl = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;
const accountAddress = process.env.ACCOUNT_ADDRESS;

if (!rpcUrl || !privateKey || !accountAddress) {
  throw new Error("Missing environment variables");
}

// connect provider
const provider = new RpcProvider({
  nodeUrl: rpcUrl
});

// connect your account. To adapt to your own account:
const account = new Account(provider, accountAddress, privateKey);

// load compiled contracts
const compiledAutoSwapprContractSierra: CompiledSierra = json.parse(
  fs
    .readFileSync("./target/dev/auto_swappr_AutoSwappr.contract_class.json")
    .toString("ascii")
);

const compiledAutoSwapprContractCasm = json.parse(
  fs
    .readFileSync(
      "./target/dev/auto_swappr_AutoSwappr.compiled_contract_class.json"
    )
    .toString("ascii")
);

/**
 * Function to deploy the AutoSwappr contract
 */
async function main() {
  // constructor params
  const supported_assets: RawCalldata = [
    "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    "0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
  ];
  const supported_assets_priceFeeds_ids: RawCalldata = ["ETH/USD", "STRK/USD"];

  const constructorParams = {
    fees_collector:
      "0x7f5a528821f37c06375a47a1c8d2ba0517a2e99ff01c01ef5068e3fb3754b87",
    fee_amount_bps: 50,
    avnu_exchange_address:
      "0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f",
    fibrous_exchange_address:
      "0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a",
    ekubo_core_address:
      "0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b",
    oracle_address:
      "0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b",
    supported_assets: supported_assets,
    supported_assets_priceFeeds_ids: supported_assets_priceFeeds_ids,
    owner: "0x01d6abf4f5963082fc6c44d858ac2e89434406ed682fb63155d146c5d69c22d6",
    initial_fee_type: 0,
    initial_percentage_fee: 100
  };

  const contractConstructor: Calldata = CallData.compile(constructorParams);
  const deployResponse = await account.declareAndDeploy({
    contract: compiledAutoSwapprContractSierra,
    casm: compiledAutoSwapprContractCasm,
    constructorCalldata: contractConstructor
  });

  const autoSwapprContract = new Contract(
    compiledAutoSwapprContractSierra.abi,
    deployResponse.deploy.contract_address,
    provider
  );
  console.log(
    "AutoSwappr Contract Class Hash =",
    deployResponse.declare.class_hash
  );
  console.log(
    "✅ AutoSwappr Contract connected at =",
    autoSwapprContract.address
  );
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
