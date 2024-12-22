// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global
};

use auto_swappr::interfaces::iautoswappr::{
    IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait, ContractInfo
};
use auto_swappr::base::types::{Route};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

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
pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IERC20Dispatcher, IERC20Dispatcher) {
    let strk_token_name: ByteArray = "STARKNET_TOKEN";

    let strk_token_symbol: ByteArray = "STRK";
    let supply: u256 = 1_000_000_000_000_000_000;

    let eth_token_name: ByteArray = "ETHER";
    let eth_token_symbol: ByteArray = "ETH";

    let erc20_class_hash = declare("ERC20Upgradeable").unwrap().contract_class();
    let mut strk_constructor_calldata = array![];
    strk_token_name.serialize(ref strk_constructor_calldata);
    strk_token_symbol.serialize(ref strk_constructor_calldata);
    supply.serialize(ref strk_constructor_calldata);
    USER().serialize(ref strk_constructor_calldata);
    OWNER().serialize(ref strk_constructor_calldata);

    let (strk_contract_address, _) = erc20_class_hash.deploy(@strk_constructor_calldata).unwrap();

    let mut eth_constructor_calldata = array![];
    eth_token_name.serialize(ref eth_constructor_calldata);
    eth_token_symbol.serialize(ref eth_constructor_calldata);
    supply.serialize(ref eth_constructor_calldata);
    USER().serialize(ref eth_constructor_calldata);
    OWNER().serialize(ref eth_constructor_calldata);

    let (eth_contract_address, _) = erc20_class_hash.deploy(@eth_constructor_calldata).unwrap();

    let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
    let eth_dispatcher = IERC20Dispatcher { contract_address: eth_contract_address };

    // deploy AutoSwappr
    let autoswappr_class_hash = declare("AutoSwappr").unwrap().contract_class();
    let mut autoSwappr_constructor_calldata: Array<felt252> = array![];
    FEE_COLLECTOR_ADDR().serialize(ref autoSwappr_constructor_calldata);
    AVNU_ADDR().serialize(ref autoSwappr_constructor_calldata);
    FIBROUS_ADDR().serialize(ref autoSwappr_constructor_calldata);
    ORACLE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    strk_contract_address.serialize(ref autoSwappr_constructor_calldata);
    eth_contract_address.serialize(ref autoSwappr_constructor_calldata);
    OWNER().serialize(ref autoSwappr_constructor_calldata);
    let (autoSwappr_contract_address, _) = autoswappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_operator(OPERATOR());
    return (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher);
}

#[test]
fn test_constructor_initializes_correctly() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let expected_contract_params = ContractInfo {
        fees_collector: FEE_COLLECTOR_ADDR(),
        fibrous_exchange_address: FIBROUS_ADDR(),
        avnu_exchange_address: AVNU_ADDR(),
        strk_token: strk_dispatcher.contract_address,
        eth_token: eth_dispatcher.contract_address,
        owner: OWNER()
    };
    let actual_contract_params = autoswappr_dispatcher.contract_parameters();
    assert_eq!(expected_contract_params, actual_contract_params);
}

#[test]
#[should_panic(expected: 'Amount is zero')]
fn test_swap_reverts_if_token_from_amount_is_zero() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone()
    };
    let token_from_address: ContractAddress = strk_dispatcher.contract_address;
    let token_from_amount: u256 = 0;
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();
    start_cheat_caller_address_global(OPERATOR());
    autoswappr_dispatcher
        .avnu_swap(
            :token_from_address,
            :token_from_amount,
            :token_to_address,
            :token_to_amount,
            :token_to_min_amount,
            :beneficiary,
            :integrator_fee_amount_bps,
            :integrator_fee_recipient,
            :routes
        );
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Token not supported')]
fn test_swap_reverts_if_token_is_not_supported() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone()
    };
    let token_from_address: ContractAddress = contract_address_const::<'RANDOM_TOKEN_ADDRESS'>();
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER());
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();
    start_cheat_caller_address_global(OPERATOR());
    autoswappr_dispatcher
        .avnu_swap(
            :token_from_address,
            :token_from_amount,
            :token_to_address,
            :token_to_amount,
            :token_to_min_amount,
            :beneficiary,
            :integrator_fee_amount_bps,
            :integrator_fee_recipient,
            :routes
        );
    stop_cheat_caller_address_global();
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
fn test_contract_fetches_eth_usd_price_correctly() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let (eth_usd_price, decimals) = autoswappr_dispatcher.get_eth_usd_price();
    print!("The eth/usd price is {} with {} decimals", eth_usd_price, decimals);
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
fn test_contract_fetches_strk_usd_price_correctly() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let (strk_usd_price, decimals) = autoswappr_dispatcher.get_strk_usd_price();
    print!("The strk/usd price is {} with {} decimals", strk_usd_price, decimals);
}

