// *************************************************************************
//                              FIBROUS SWAP TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait,
    start_cheat_account_contract_address,
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
    0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const ETH_TOKEN_ADDRESS: felt252 =
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

const ADDRESS_WITH_STRK_1:felt252 = 0x0298a9d0d82aabfd7e2463bb5ec3590c4e86d03b2ece868d06bbe43475f2d3e6;
const ADDRESS_WITH_ETH_1:felt252 = 0x03a20d4f7b4229e7c4863dab158b4d076d7f454b893d90a62011882dc4caca2a;


// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
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
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
fn test_fibrous_swap() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = contract_address_const::<ADDRESS_WITH_STRK_1>();
    let amount_to_swap = 1000000000000000000; // 1 STRK
    let strk_token = IERC20Dispatcher { contract_address: contract_address_const::<STRK_TOKEN_ADDRESS>() };
    
    // funding swapper contract to pay for gas when call fibrous exchange contract
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token.transfer(autoSwappr_dispatcher.contract_address, 20000000000000000000);
    stop_cheat_caller_address(strk_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token
    .approve(
        contract_address_const::<FIBROUS_EXCHANGE_ADDRESS>(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(strk_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: contract_address_const::<STRK_TOKEN_ADDRESS>(),
        token_out: contract_address_const::<ETH_TOKEN_ADDRESS>(),
        amount_in: amount_to_swap,
        // min_received:631641,
        min_received:601641,
        destination: contract_address_const::<0xf28cdd1f902402cab752904d855fa52608d5ae63f1c69ed038049260cad3d7>(), // any starknet wallet
    };

    let swapParamsItem = SwapParams {
        token_in: contract_address_const::<STRK_TOKEN_ADDRESS>(),
        token_out: contract_address_const::<ETH_TOKEN_ADDRESS>(),
        pool_address: contract_address_const::<0x5726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26>(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];

    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(contract_address_const::<FIBROUS_EXCHANGE_ADDRESS>(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
                routeParams,
                swapParams,
            );
}

