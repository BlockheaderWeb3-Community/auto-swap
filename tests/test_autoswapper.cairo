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

const FEE_AMOUNT_BPS: u8 = 50; // $0.5 fee

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
    let autoSwappr_contract_address = deploy_autoSwappr(array![eth_contract_address, strk_contract_address],  array!['ETH/USD', 'STRK/USD']); 
    
    return (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher);
}

fn deploy_autoSwappr( supported_assets: Array<ContractAddress>,
        supported_assets_priceFeeds_ids: Array<felt252>) -> ContractAddress {
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
    let (autoSwappr_contract_address, _) = autoswappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_operator(OPERATOR());
    autoSwappr_contract_address
}

#[test]
#[should_panic]
fn test_constructor_reverts_if_supported_assets_array_is_empty() {
    deploy_autoSwappr(array![], array!['ETH/USD', 'STRK/USD']);
}

#[test]
#[should_panic]
fn test_constructor_reverts_if_supported_assets_array_length_doesnt_match_priceFeedId_array_length() {
    let eth_contract_address: ContractAddress = contract_address_const::<'ETH_TOKEN_ADDRESS'>();
    let strk_contract_address: ContractAddress = contract_address_const::<'STRK_TOKEN_ADDRESS'>();
    let wbtc_contract_address: ContractAddress = contract_address_const::<'WBTC_TOKEN_ADDRESS'>();
    let supported_assets = array![eth_contract_address, strk_contract_address, wbtc_contract_address];
    deploy_autoSwappr(supported_assets, array!['ETH/USD', 'STRK/USD']); 
}

#[test]
fn test_constructor_initializes_correctly() {
    let (autoSwappr_contract_address, _, _,) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let expected_contract_params = ContractInfo {
        fees_collector: FEE_COLLECTOR_ADDR(),
        fibrous_exchange_address: FIBROUS_ADDR(),
        avnu_exchange_address: AVNU_ADDR(),
        oracle_address: ORACLE_ADDRESS(),
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
fn test_is_operator() {
    let (autoSwappr_contract_address, _, _) = __setup__();

    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone()
    };

    start_cheat_caller_address_global(OWNER());

    assert(autoSwappr_dispatcher.is_operator(USER()) == false, 'non operator');

    autoSwappr_dispatcher.set_operator(USER());

    assert(autoSwappr_dispatcher.is_operator(USER()) == true, 'is operator');
    stop_cheat_caller_address_global();
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_contract_fetches_eth_usd_price_correctly() {
    let (autoSwappr_contract_address, _, eth_dispatcher) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let eth_amount = 10; // 1 ether
    let usd_amount = autoswappr_dispatcher.get_token_amount_in_usd(eth_dispatcher.contract_address, eth_amount);
    println!("{} eth in usd using pragma oracle is {}", eth_amount, usd_amount);
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_contract_fetches_strk_usd_price_correctly() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let strk_amount = 1000; // 100 strk

    let usd_amount = autoswappr_dispatcher.get_token_amount_in_usd(strk_dispatcher.contract_address, strk_amount);
    println!("{} strk in usd using pragma oracle is {}", strk_amount, usd_amount);
}
