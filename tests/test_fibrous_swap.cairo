// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait,
};

use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{RouteParams, SwapParams};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

const OWNER: felt252 = 'OWNER';

const FEE_COLLECTOR: felt252 = 0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;
const AVNU_EXCHANGE_ADDRESS: felt252 =
    0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f;
const FIBROUS_EXCHANGE_ADDRESS: felt252 =
    0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a;
const STRK_TOKEN_ADDRESS: felt252 =
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const ETH_TOKEN_ADDRESS: felt252 =
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

const ADDRESS_WITH_STRK_1:felt252 = 0x0631c2f9043db0d45576045fdd3e417f81dcb0ae0bdcdcfa415c88b4cd7fc56b;



// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // deploy  events
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut auto_swappr_constructor_calldata: Array<felt252> = array![
        FEE_COLLECTOR, AVNU_EXCHANGE_ADDRESS, FIBROUS_EXCHANGE_ADDRESS, STRK_TOKEN_ADDRESS, ETH_TOKEN_ADDRESS, OWNER,
    ];

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@auto_swappr_constructor_calldata)
        .unwrap();

    auto_swappr_contract_address
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 982171)]
fn test_fibrous_swap() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

    let address_with_funds = contract_address_const::<ADDRESS_WITH_STRK_1>();

        let routeParams = RouteParams {
            token_in: contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>(),
            token_out: contract_address_const::<0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8>(),
            amount_in: 1000000000000000000,
            min_received:631641,
            destination: contract_address_const::<0xf28cdd1f902402cab752904d855fa52608d5ae63f1c69ed038049260cad3d7>(), // any starknet wallet
        };

        let swapParamsItem = SwapParams {
            token_in: contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>(),
            token_out: contract_address_const::<0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8>(),
            pool_address: contract_address_const::<0x5726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26>(), // Ekubo
            rate: 1000000,
            protocol_id: 2,
            extra_data: array![],
        };
        let swapParams = array![swapParamsItem];

        start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
       
        autoSwappr_dispatcher
            .fibrous_swap(
                routeParams,
                swapParams,
            );
}


#[test]
#[should_panic(expected: 'Insufficient Balance')]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 979167)]
fn test_fibrous_swap_should_fail_for_inssuficient_balance() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

        let routeParams = RouteParams {
            token_in: contract_address_const::<STRK_TOKEN_ADDRESS>(),
            token_out: contract_address_const::<ETH_TOKEN_ADDRESS>(),
            amount_in: 10000,
            min_received: 900,
            destination: contract_address_const::<123>(),
        };

        let swapParamsItem = SwapParams {
            token_in: contract_address_const::<123>(),
            token_out: contract_address_const::<456>(),
            pool_address: contract_address_const::<456>(),
            rate: 2,
            protocol_id: 3,
            extra_data: array![1],
        };
        let swapParams = array![swapParamsItem];

        autoSwappr_dispatcher
            .fibrous_swap(
                routeParams,
                swapParams,
            );
}

#[test]
#[should_panic(expected: 'Token not supported')]
// #[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

        let routeParams = RouteParams {
            token_in: contract_address_const::<123>(),
            token_out: contract_address_const::<456>(),
            amount_in: 15,
            min_received: 10,
            destination: contract_address_const::<789>(),
        };

        let swapParamsItem = SwapParams {
            token_in: contract_address_const::<123>(),
            token_out: contract_address_const::<456>(),
            pool_address: contract_address_const::<789>(),
            rate: 2,
            protocol_id: 3,
            extra_data: array![1,2,3,4],
        };
        let swapParams = array![swapParamsItem];

        autoSwappr_dispatcher
            .fibrous_swap(
                routeParams,
                swapParams,
            );
}