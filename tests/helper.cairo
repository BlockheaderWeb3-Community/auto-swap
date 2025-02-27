mod Helper {
pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
pub fn FEE_COLLECTOR_ADDR() -> ContractAddress {
    contract_address_const::<'FEE_COLLECTOR_ADDR'>()
}

pub fn AVNU_ADDR() -> ContractAddress {
    contract_address_const::<'AVNU_ADDR'>()
}
pub fn FIBROUS_ADDR() -> ContractAddress {
    contract_address_const::<'FIBROUS_ADDR'>()
}
pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}
pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}
pub fn NEW_OPERATOR() -> ContractAddress {
    contract_address_const::<'NEW_OPERATOR'>()
}
pub fn RANDOM_TOKEN() -> ContractAddress {
    contract_address_const::<'RANDOM_TOKEN'>()
}
pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}
pub fn NON_EXISTENT_OPERATOR() -> ContractAddress {
    contract_address_const::<'NON_EXISTENT_OPERATOR'>()
}

pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}

const FEE_AMOUNT_BPS: u8 = 50; // $0.5 fee

const INITIAL_FEE_TYPE: FeeType = FeeType::Fixed;
const INITIAL_PERCENTAGE_FEE: u16 = 100;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IOperatorDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
    let strk_token_name: ByteArray = "STARKNET_TOKEN";

    let strk_token_symbol: ByteArray = "STRK";

    let decimals: u8 = 18;

    let eth_token_name: ByteArray = "ETHER";
    let eth_token_symbol: ByteArray = "ETH";

    let erc20_class_hash = declare("ERC20Upgradeable").unwrap().contract_class();
    let mut strk_constructor_calldata = array![];
    strk_token_name.serialize(ref strk_constructor_calldata);
    strk_token_symbol.serialize(ref strk_constructor_calldata);
    decimals.serialize(ref strk_constructor_calldata);
    OWNER().serialize(ref strk_constructor_calldata);

    let (strk_contract_address, _) = erc20_class_hash.deploy(@strk_constructor_calldata).unwrap();

    let strk_mintable_dispatcher = IERC20MintableDispatcher {
        contract_address: strk_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    strk_mintable_dispatcher.mint(USER(), 1_000_000_000_000_000_000);
    stop_cheat_caller_address_global();

    let mut eth_constructor_calldata = array![];
    eth_token_name.serialize(ref eth_constructor_calldata);
    eth_token_symbol.serialize(ref eth_constructor_calldata);
    decimals.serialize(ref eth_constructor_calldata);
    OWNER().serialize(ref eth_constructor_calldata);

    let (eth_contract_address, _) = erc20_class_hash.deploy(@eth_constructor_calldata).unwrap();

    let eth_mintable_dispatcher = IERC20MintableDispatcher {
        contract_address: eth_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    eth_mintable_dispatcher.mint(USER(), 1_000_000_000_000_000_000);
    stop_cheat_caller_address_global();

    let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
    let eth_dispatcher = IERC20Dispatcher { contract_address: eth_contract_address };

    // deploy AutoSwappr
    let (autoSwappr_contract_address, operator_dispatcher) = deploy_autoSwappr(
        array![eth_contract_address, strk_contract_address], array!['ETH/USD', 'STRK/USD']
    );

    return (autoSwappr_contract_address, operator_dispatcher, strk_dispatcher, eth_dispatcher);
}

fn deploy_autoSwappr(
    supported_assets: Array<ContractAddress>, supported_assets_priceFeeds_ids: Array<felt252>
) -> (ContractAddress, IOperatorDispatcher) {
    let autoswappr_class_hash = declare("AutoSwappr").unwrap().contract_class();
    let mut autoSwappr_constructor_calldata: Array<felt252> = array![];
    FEE_COLLECTOR_ADDR().serialize(ref autoSwappr_constructor_calldata);
    FEE_AMOUNT_BPS.serialize(ref autoSwappr_constructor_calldata);
    AVNU_ADDR().serialize(ref autoSwappr_constructor_calldata);
    FIBROUS_ADDR().serialize(ref autoSwappr_constructor_calldata);
    ORACLE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    supported_assets.serialize(ref autoSwappr_constructor_calldata);
    supported_assets_priceFeeds_ids.serialize(ref autoSwappr_constructor_calldata);
    OWNER().serialize(ref autoSwappr_constructor_calldata);
    INITIAL_FEE_TYPE.serialize(ref autoSwappr_constructor_calldata);
    INITIAL_PERCENTAGE_FEE.serialize(ref autoSwappr_constructor_calldata);
    let (autoSwappr_contract_address, _) = autoswappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    let operator_dispatcher = IOperatorDispatcher { contract_address: autoSwappr_contract_address };

    start_cheat_caller_address_global(OWNER());
    operator_dispatcher.set_operator(OPERATOR());

    (autoSwappr_contract_address, operator_dispatcher)
}
}
