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
const USDC_TOKEN_ADDRESS: felt252 =
    0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8;

const STK_MINTER_ADDRESS: felt252 =
    0x0594c1582459ea03f77deaf9eb7e3917d6994a03c13405ba42867f83d85f085d;
const SWAP_CALLER_ADDRESS: felt252 =
    0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;


const JEDISWAP_ROUTER_ADDRESS: felt252 =
    0x041fd22b238fa21cfcf5dd45a8548974d8263b3a531a60388411c5e230f97023;

const ADDRESS_WITH_STRK_1:felt252 = 0x0298a9d0d82aabfd7e2463bb5ec3590c4e86d03b2ece868d06bbe43475f2d3e6;



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
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 979167)]
fn test_fibrous_swap() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
        let routeParams = RouteParams {
            token_in: contract_address_const::<ETH_TOKEN_ADDRESS>(),
            token_out: contract_address_const::<STRK_TOKEN_ADDRESS>(),
            amount_in: 10000000000000000,
            min_received:1000000,
            destination: contract_address_const::<0x0092fB909857ba418627B9e40A7863F75768A0ea80D306Fb5757eEA7DdbBd4Fc>(), // any starknet wallet
        };

        let swapParamsItem = SwapParams {
            token_in: contract_address_const::<ETH_TOKEN_ADDRESS>(),
            token_out: contract_address_const::<STRK_TOKEN_ADDRESS>(),
            pool_address: contract_address_const::<0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b>(), // Ekubo
            rate: 1000000,
            protocol_id: 5,
            extra_data: array![],
        };
        let swapParams = array![swapParamsItem];

        // Prefund contract for gas
        let eth_token = IERC20Dispatcher { contract_address: contract_address_const::<ETH_TOKEN_ADDRESS>() };
        let address_with_funds = contract_address_const::<ADDRESS_WITH_STRK_1>();

        start_cheat_caller_address(eth_token.contract_address, address_with_funds);
        eth_token
        .approve(
            autoSwappr_dispatcher.contract_address,
            20000000000000000
        );
        stop_cheat_caller_address(eth_token.contract_address);
        //

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

// #[test]
// #[fork("Mainnet")]
// fn test_swap() {
//     let autoswappr_contract_address = __setup__();
//     let autoswappr_contract = IAutoSwapprDispatcher {
//         contract_address: autoswappr_contract_address,
//     };

//     let strk_token_address = contract_address_const::<STRK_TOKEN_ADDRESS>();
//     let minter_address = contract_address_const::<STK_MINTER_ADDRESS>();
//     let caller = contract_address_const::<SWAP_CALLER_ADDRESS>();

//     let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
//     let mint_amount: u256 = 500 * ONE_E18;

//     // Mint STRK to caller
//     start_cheat_caller_address(strk_token_address, minter_address);
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     caller.serialize(ref calldata);
//     mint_amount.serialize(ref calldata);
//     call_contract_syscall(strk_token_address, selector!("permissioned_mint"), calldata.span())
//         .unwrap();
//     stop_cheat_caller_address(strk_token_address);
//     assert(strk_token.balance_of(caller) == mint_amount, 'invalid balance');

//     // Prank caller to approve auto_swapper
//     start_cheat_caller_address(strk_token_address, caller);
//     strk_token.approve(autoswappr_contract_address, mint_amount);
//     stop_cheat_caller_address(strk_token_address);
//     assert(
//         strk_token.allowance(caller, autoswappr_contract_address) == mint_amount,
//         'invalid allowance',
//     );

//     // Prank caller to and call swap() function in auto_swapper
//     start_cheat_caller_address(autoswappr_contract_address, caller);
//     let token_from_address = strk_token_address.clone();
//     let token_from_amount: u256 = 5 * ONE_E18;
//     let token_to_address = contract_address_const::<USDC_TOKEN_ADDRESS>();
//     let token_to_amount: u256 = 2 * ONE_E6;
//     let token_to_min_amount: u256 = 2 * ONE_E6;
//     let beneficiary = autoswappr_contract_address;
//     let mut routes = ArrayTrait::new();

//     routes
//         .append(
//             Route {
//                 token_from: token_from_address,
//                 token_to: token_to_address,
//                 exchange_address: contract_address_const::<JEDISWAP_ROUTER_ADDRESS>(),
//                 percent: 100,
//                 additional_swap_params: ArrayTrait::new(),
//             },
//         );

//     autoswappr_contract
//         .swap(
//             token_from_address,
//             token_from_amount,
//             token_to_address,
//             token_to_amount,
//             token_to_min_amount,
//             beneficiary,
//             0,
//             contract_address_const::<SWAP_CALLER_ADDRESS>(),
//             routes,
//         );
//     stop_cheat_caller_address(autoswappr_contract_address);
// }
