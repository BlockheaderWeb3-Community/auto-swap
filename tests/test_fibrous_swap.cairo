// *************************************************************************
//                              FIBROUS SWAP TEST
// *************************************************************************

// starknet imports
use starknet::{ContractAddress, contract_address_const};
// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
// Autoswappr imports
use auto_swappr::base::types::{RouteParams, SwapParams};

use crate::constants::{
    USDT_TOKEN_ADDRESS, AMOUNT_TO_SWAP_STRK, AMOUNT_TO_SWAP_ETH, FEE_COLLECTOR, STRK_TOKEN,
    ETH_TOKEN, USDT_TOKEN, USDC_TOKEN, FEE_AMOUNT, MIN_RECEIVED_STRK_TO_STABLE,
    MIN_RECEIVED_ETH_TO_STABLE, JEDISWAP_POOL_ADDRESS, SwapType
};

use crate::utils::{
    __setup__, call_fibrous_swap, get_wallet_amounts, approve_amount, get_swap_parameters
};

pub fn ADDRESS_WITH_FUNDS() -> ContractAddress {
    // 0.01 ETH - 8.4 STRK
    contract_address_const::<0x049c6e318b49bfba4f38dd839e7a44010119c6188d1574e406dbbedef29d096d>()
}


#[test]
#[fork("MAINNET", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdt() {
    let autoSwappr_dispatcher = __setup__();
    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    // contract address has to be passed so it can be used as destination address for the swaps
    let (routeParams, swapParams) = get_swap_parameters(
        SwapType::strk_usdt, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());

    // asserts
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_STRK_TO_STABLE - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // fee collector assertion
    assert_eq!(
        USDT_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdt + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let (routeParams, swapParams) = get_swap_parameters(
        SwapType::strk_usdc, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());

    // asserts
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_STRK_TO_STABLE - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // fee collector assertion
    assert_eq!(
        USDC_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdc + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 993231)]
fn test_fibrous_swap_eth_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams, swapParams) = get_swap_parameters(
        SwapType::eth_usdt, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());

    // asserts
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_ETH_TO_STABLE - FEE_AMOUNT,
        "Balance of to token should increase"
    );
    // fee collector assertion
    assert_eq!(
        USDT_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdt + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 993231)]
fn test_fibrous_swap_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams, swapParams) = get_swap_parameters(
        SwapType::eth_usdc, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());

    // asserts
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_ETH_TO_STABLE - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // fee collector assertion
    assert_eq!(
        USDC_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdc + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdt_and_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams_strk_to_usdt, swapParams_strk_to_usdt) = get_swap_parameters(
        SwapType::strk_usdt, autoSwappr_dispatcher.contract_address
    );
    let (routeParams_eth_to_usdc, swapParams_eth_to_usdc) = get_swap_parameters(
        SwapType::eth_usdc, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(
        autoSwappr_dispatcher,
        routeParams_strk_to_usdt,
        swapParams_strk_to_usdt,
        ADDRESS_WITH_FUNDS()
    );
    call_fibrous_swap(
        autoSwappr_dispatcher, routeParams_eth_to_usdc, swapParams_eth_to_usdc, ADDRESS_WITH_FUNDS()
    );

    // asserts
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "STRK Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_STRK_TO_STABLE - FEE_AMOUNT,
        "USDT Balance of to token should increase"
    );
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "ETH Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_ETH_TO_STABLE - FEE_AMOUNT,
        "USDC Balance of to token should increase"
    );

    // fee collector assertion
    assert_eq!(
        USDC_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdc + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
    assert_eq!(
        USDT_TOKEN().balance_of(FEE_COLLECTOR.try_into().unwrap()),
        previous_fee_collector_amounts.usdt + FEE_AMOUNT,
        "Fee collector balance should increase by fee amount"
    );
}


#[test]
#[fork("MAINNET", block_number: 993231)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_fibrous_swap_should_fail_for_insufficient_allowance_to_contract() {
    let autoSwappr_dispatcher = __setup__();

    // not allow so the error will occurs
    // approve_amount(STRK_TOKEN().contract_address, ADDRESS_WITH_FUNDS(),
    // autoSwappr_dispatcher.contract_address,  AMOUNT_TO_SWAP_STRK);

    let (routeParams, swapParams) = get_swap_parameters(
        SwapType::strk_usdt, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());
}

#[test]
#[fork("MAINNET", block_number: 993231)]
#[should_panic(expected: 'Token not supported')]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    let autoSwappr_dispatcher = __setup__();

    let unsupported_token = contract_address_const::<0x123>();

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let routeParams = RouteParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: autoSwappr_dispatcher.contract_address,
    };

    let swapParamsItem = SwapParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(),
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];

    // Calling function
    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams, ADDRESS_WITH_FUNDS());
}

#[test]
#[fork("MAINNET", block_number: 993231)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_should_fail_after_token_approval_is_revoked_fibrous() {
    let autoSwappr_dispatcher = __setup__();
    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let (routeParams1, swapParams1) = get_swap_parameters(
        SwapType::strk_usdt, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams1, swapParams1, ADDRESS_WITH_FUNDS());

    let post_swap_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        post_swap_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "First swap should decrease STRK balance"
    );

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        0
    );

    let (routeParams2, swapParams2) = get_swap_parameters(
        SwapType::strk_usdt, autoSwappr_dispatcher.contract_address
    );

    call_fibrous_swap(autoSwappr_dispatcher, routeParams2, swapParams2, ADDRESS_WITH_FUNDS());
}

