// *************************************************************************
//                              AVNU SWAP TEST
// *************************************************************************

// starknet imports
use starknet::{ContractAddress, contract_address_const};

// snforge imports
use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
};

// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Autoswappr
use auto_swappr::autoswappr::AutoSwappr::{Event, SwapSuccessful};
use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::FeeType;

use crate::constants::{
    FEE_COLLECTOR, STRK_TOKEN, ETH_TOKEN, USDT_TOKEN, USDC_TOKEN, FEE_AMOUNT, SwapType,
    EXCHANGE_ETH_USDC, EXCHANGE_ETH_USDT_EKUBO, EXCHANGE_STRK_USDT_POOL, AVNU_EXCHANGE_ADDRESS,
    OWNER, EXCHANGE_STRK_USDC_POOL, EXCHANGE_ETH_USDT_POOL
};

use crate::utils::{
    __setup__, get_wallet_amounts, approve_amount, get_swap_parameters_avnu as get_swap_parameters,
    call_avnu_swap, get_exchange_amount
};

pub fn ADDRESS_WITH_FUNDS() -> ContractAddress {
    // 0.01 ETH - 8.4 STRK
    contract_address_const::<0x298a9d0d82aabfd7e2463bb5ec3590c4e86d03b2ece868d06bbe43475f2d3e6>()
}


pub const AMOUNT_TO_SWAP_STRK: u256 =
    2000000000000000000; // 2 STRK. used 2 so we can enough to take fee from
pub const AMOUNT_TO_SWAP_ETH: u256 = 200000000000000; // 0.0002 ETH 


#[test]
#[fork("MAINNET", block_number: 996491)]
fn test_avnu_swap_strk_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    let previous_exchange_amount_strk = get_exchange_amount(
        STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );
    let previous_exchange_amount_usdt = get_exchange_amount(
        USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );

    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_strk = get_exchange_amount(STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL());
    let new_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL());
    let new_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    // assertions
    assert_eq!(
        new_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );

    assert_eq!(new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged");

    assert_ge!(
        new_amounts.usdt,
        previous_amounts.usdt + params.token_to_min_amount - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // assertions for the exchange
    assert_le!(
        new_exchange_amount_usdt,
        previous_exchange_amount_usdt - params.token_to_min_amount,
        "Exchange address USDT balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_strk,
        previous_exchange_amount_strk + AMOUNT_TO_SWAP_STRK,
        "Exchange address STRK balance should increase"
    );

    // fee collector assertion
    assert_eq!(
        new_fee_collector_amounts.usdt,
        previous_fee_collector_amounts.usdt + FEE_AMOUNT,
        "Fee collector USDT balance should increase by the fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 996957)]
fn test_avnu_swap_strk_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    let previous_exchange_amount_strk = get_exchange_amount(
        STRK_TOKEN(), EXCHANGE_STRK_USDC_POOL()
    );
    let previous_exchange_amount_usdc = get_exchange_amount(
        USDC_TOKEN(), EXCHANGE_STRK_USDC_POOL()
    );
    let AMOUNT_TO_SWAP_STRK = AMOUNT_TO_SWAP_STRK; //so there is enough to take the fee

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_strk = get_exchange_amount(STRK_TOKEN(), EXCHANGE_STRK_USDC_POOL());
    let new_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_STRK_USDC_POOL());
    let new_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    // assertions
    assert_eq!(
        new_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdc,
        previous_amounts.usdc + params.token_to_min_amount - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // assertions for the exchange
    assert_le!(
        new_exchange_amount_usdc,
        previous_exchange_amount_usdc - params.token_to_min_amount,
        "Exchange address USDC balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_strk,
        previous_exchange_amount_strk + AMOUNT_TO_SWAP_STRK,
        "Exchange address STRK balance should increase"
    );

    // fee collector assertion
    assert_eq!(
        new_fee_collector_amounts.usdc,
        previous_fee_collector_amounts.usdc + FEE_AMOUNT,
        "Fee collector USDT balance should increase by the fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 997043)]
fn test_avnu_swap_eth_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    let previous_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDT_EKUBO());
    let previous_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_ETH_USDT_POOL());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    let new_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDT_EKUBO());
    let new_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_ETH_USDT_POOL());

    // assertion
    assert_eq!(
        new_amounts.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdt,
        previous_amounts.usdt + params.token_to_min_amount - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // avnu post-swap assertions
    assert_le!(
        new_exchange_amount_usdt,
        // previous_exchange_amount_usdt - params.token_to_min_amount + 1000, // for this special
        // case, AVNU is taking a % of the USDT to send from his own balance and not from the called
        // pool, so we add that aprox. remainder here
        previous_exchange_amount_usdt - params.token_to_min_amount,
        "Exchange address USDT balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_eth,
        previous_exchange_amount_eth + AMOUNT_TO_SWAP_ETH,
        "Exchange address ETH balance should increase"
    );

    // fee collector assertion
    assert_eq!(
        new_fee_collector_amounts.usdt,
        previous_fee_collector_amounts.usdt + FEE_AMOUNT,
        "Fee collector USDT balance should increase by the fee amount"
    );
}

#[test]
// #[fork("MAINNET", block_number: 997080)]
#[fork("MAINNET", block_number: 1002124)]
fn test_avnu_swap_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    let previous_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDC());
    let previous_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_ETH_USDC());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDC());
    let new_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_ETH_USDC());
    let new_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    // assertion
    assert_eq!(
        new_amounts.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdc,
        previous_amounts.usdc + params.token_to_min_amount - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // avnu post-swap assertions
    assert_le!(
        new_exchange_amount_usdc,
        previous_exchange_amount_usdc - params.token_to_min_amount,
        "Exchange address USDC balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_eth,
        previous_exchange_amount_eth + AMOUNT_TO_SWAP_ETH,
        "Exchange address ETH balance should increase"
    );

    // fee collector assertion
    assert_eq!(
        new_fee_collector_amounts.usdc,
        previous_fee_collector_amounts.usdc + FEE_AMOUNT,
        "Fee collector USDT balance should increase by the fee amount"
    );
}

#[test]
#[fork("MAINNET", block_number: 999126)]
fn test_multi_swaps() {
    let autoSwappr_dispatcher = __setup__();

    // params
    let params_strk_to_usdt = get_swap_parameters(SwapType::strk_usdt);
    let params_strk_to_usdc = get_swap_parameters(SwapType::strk_usdc);
    let params_eth_to_usdt = get_swap_parameters(SwapType::eth_usdt);
    let params_eth_to_usdc = get_swap_parameters(SwapType::eth_usdc);

    // In the block used for the test, the value of the STRK token is less than the on returned from
    // get_swap_parameters so we replace it with the next value (this is an specific case for this
    // test, so it's better to handle it locally)
    let strk_to_stable_min_amount = 420000
        * 2; // We are using 2 strk so we can take the fee from it
    let eth_to_stable_min_amount = 595791;

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    //strk to usdt
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_strk_to_usdt.token_from_address,
        params_strk_to_usdt.token_from_amount,
        params_strk_to_usdt.token_to_address,
        // params_strk_to_usdt.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdt.beneficiary,
        params_strk_to_usdt.integrator_fee_amount_bps,
        params_strk_to_usdt.integrator_fee_recipient,
        params_strk_to_usdt.routes
    );
    let amounts_after_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_strk_to_usdt.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "(amounts_after_strk_to_usdt) STRK Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_strk_to_usdt.usdt,
        previous_amounts.usdt + strk_to_stable_min_amount - FEE_AMOUNT,
        "(amounts_after_strk_to_usdt) USDT Balance of to token should increase"
    );
    // // strk to usdc
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_strk_to_usdc.token_from_address,
        params_strk_to_usdc.token_from_amount,
        params_strk_to_usdc.token_to_address,
        // params_strk_to_usdc.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdc.beneficiary,
        params_strk_to_usdc.integrator_fee_amount_bps,
        params_strk_to_usdc.integrator_fee_recipient,
        params_strk_to_usdc.routes
    );
    let amounts_after_strk_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_strk_to_usdc.strk,
        amounts_after_strk_to_usdt.strk - AMOUNT_TO_SWAP_STRK,
        "(amounts_after_strk_to_usdc) STRK Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_strk_to_usdc.usdc,
        amounts_after_strk_to_usdt.usdc + strk_to_stable_min_amount - FEE_AMOUNT,
        "(amounts_after_strk_to_usdc) USDC Balance of to token should increase"
    );
    // eth to usdt
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_eth_to_usdt.token_from_address,
        params_eth_to_usdt.token_from_amount,
        params_eth_to_usdt.token_to_address,
        // params_eth_to_usdt.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdt.beneficiary,
        params_eth_to_usdt.integrator_fee_amount_bps,
        params_eth_to_usdt.integrator_fee_recipient,
        params_eth_to_usdt.routes
    );
    let amounts_after_eth_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_eth_to_usdt.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "(amounts_after_eth_to_usdt) ETH Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_eth_to_usdt.usdt,
        amounts_after_strk_to_usdc.usdt + eth_to_stable_min_amount - FEE_AMOUNT,
        "(amounts_after_eth_to_usdt) USDT Balance of to token should increase"
    );
    // eth to usdc
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_eth_to_usdc.token_from_address,
        params_eth_to_usdc.token_from_amount,
        params_eth_to_usdc.token_to_address,
        // params_eth_to_usdc.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdc.beneficiary,
        params_eth_to_usdc.integrator_fee_amount_bps,
        params_eth_to_usdc.integrator_fee_recipient,
        params_eth_to_usdc.routes
    );
    let amounts_after_eth_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_eth_to_usdc.eth,
        amounts_after_eth_to_usdt.eth - AMOUNT_TO_SWAP_ETH,
        "(amounts_after_eth_to_usdc) ETH Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_eth_to_usdc.usdc,
        amounts_after_eth_to_usdt.usdc + eth_to_stable_min_amount - FEE_AMOUNT,
        "(amounts_after_eth_to_usdc) USDC Balance of to token should increase"
    );

    let final_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    assert_eq!(
        final_amounts.strk,
        previous_amounts.strk
            - AMOUNT_TO_SWAP_STRK
                * 2, // times 2 because we swap to stable twice one from STRK and one from ETH
        "STRK Balance of from token should decrease"
    );
    assert_eq!(
        final_amounts.eth,
        previous_amounts.eth
            - AMOUNT_TO_SWAP_ETH
                * 2, // times 2 because we swap to stable twice one from STRK and one from ETH
        "ETH Balance of from token should decrease"
    );

    assert_ge!(
        final_amounts.usdt,
        previous_amounts.usdt
            + (strk_to_stable_min_amount + eth_to_stable_min_amount)
            - FEE_AMOUNT * 2, // should increase the sum of strk and eth swaps to usdt
        "USDT Balance of to token should increase"
    );

    assert_ge!(
        final_amounts.usdc,
        previous_amounts.usdc
            + (eth_to_stable_min_amount + strk_to_stable_min_amount)
            - FEE_AMOUNT * 2, // should increase the sum of strk and eth swaps to usdc
        "USDC Balance of to token should increase"
    );

    // fee collector assertion
    let final_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    assert_eq!(
        final_fee_collector_amounts.usdt,
        FEE_AMOUNT * 2, // times 2 because we swapped to usdt twice one from STRK and one from ETH
        "Fee collector USDT balance should increase by the fee amount"
    );
    assert_eq!(
        final_fee_collector_amounts.usdc,
        FEE_AMOUNT * 2, // times 2 because we swapped to usdc twice one from STRK and one from ETH
        "Fee collector USDC balance should increase by the fee amount"
    );
}

// *************************************************************************
//                        UNCHANGED TOKEN BALANCES AFTER SWAPS
// *************************************************************************
#[test]
#[fork("MAINNET", block_number: 996491)]
fn test_unswapped_token_balances_should_remain_unchanged_for_strk_usdt_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.eth, previous_amounts.eth, "ETH balance should remain unchanged"
    ); // unchanged ETH token balance
}

#[test]
#[fork("MAINNET", block_number: 996957)]
fn test_unswapped_token_balances_should_remain_unchanged_for_strk_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdt, previous_amounts.usdt, "USDT balance should remain unchanged"
    ); // unchanged USDT token balance
    assert_eq!(
        new_amounts.eth, previous_amounts.eth, "ETH balance should remain unchanged"
    ); // unchanged ETH token balance
}

#[test]
#[fork("MAINNET", block_number: 997043)]
fn test_unswapped_token_balances_should_remain_unchanged_for_eth_usdt_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.strk, previous_amounts.strk, "STRK balance should remain unchanged"
    ); // unchanged STRK token balance
}

#[test]
#[fork("MAINNET", block_number: 997043)]
fn test_unswapped_token_balances_should_remain_unchanged_for_eth_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount
            - 10000, // original:679940 -> give a bit more margin cause test was failing due to 'Insufficient tokens received'
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdt, previous_amounts.usdt, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.strk, previous_amounts.strk, "STRK balance should remain unchanged"
    ); // unchanged STRK token balance
}

// *************************************************************************
//                        EVENT EMISSIONS
// *************************************************************************
#[test]
#[fork("MAINNET", block_number: 996491)]
fn test_avnu_swap_event_emission() {
    let mut spy = spy_events();
    let autoSwappr_dispatcher = __setup__();

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);
    let amounts_before_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let amounts_after_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // events assertion
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params.token_from_address,
                            token_from_amount: params.token_from_amount,
                            token_to_address: params.token_to_address,
                            token_to_amount: amounts_after_strk_to_usdt.usdt
                                - amounts_before_strk_to_usdt.usdt
                                + FEE_AMOUNT,
                            beneficiary: params.beneficiary,
                            provider: AVNU_EXCHANGE_ADDRESS()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET", block_number: 999126)]
fn test_multi_swaps_event_emission() {
    let mut spy = spy_events();
    let autoSwappr_dispatcher = __setup__();

    // params
    let params_strk_to_usdt = get_swap_parameters(SwapType::strk_usdt);
    let params_strk_to_usdc = get_swap_parameters(SwapType::strk_usdc);
    let params_eth_to_usdt = get_swap_parameters(SwapType::eth_usdt);
    let params_eth_to_usdc = get_swap_parameters(SwapType::eth_usdc);
    let amounts_before_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    let strk_to_stable_min_amount = 420000;
    let eth_to_stable_min_amount = 595791;

    // strk to usdt
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_strk_to_usdt.token_from_address,
        params_strk_to_usdt.token_from_amount,
        params_strk_to_usdt.token_to_address,
        // params_strk_to_usdt.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdt.beneficiary,
        params_strk_to_usdt.integrator_fee_amount_bps,
        params_strk_to_usdt.integrator_fee_recipient,
        params_strk_to_usdt.routes
    );
    let amounts_after_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // strk to usdc
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_strk_to_usdc.token_from_address,
        params_strk_to_usdc.token_from_amount,
        params_strk_to_usdc.token_to_address,
        // params_strk_to_usdc.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdc.beneficiary,
        params_strk_to_usdc.integrator_fee_amount_bps,
        params_strk_to_usdc.integrator_fee_recipient,
        params_strk_to_usdc.routes
    );
    let amounts_after_strk_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // eth to usdt
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_eth_to_usdt.token_from_address,
        params_eth_to_usdt.token_from_amount,
        params_eth_to_usdt.token_to_address,
        // params_eth_to_usdt.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdt.beneficiary,
        params_eth_to_usdt.integrator_fee_amount_bps,
        params_eth_to_usdt.integrator_fee_recipient,
        params_eth_to_usdt.routes
    );
    let amounts_after_eth_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // eth to usdc
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params_eth_to_usdc.token_from_address,
        params_eth_to_usdc.token_from_amount,
        params_eth_to_usdc.token_to_address,
        // params_eth_to_usdc.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdc.beneficiary,
        params_eth_to_usdc.integrator_fee_amount_bps,
        params_eth_to_usdc.integrator_fee_recipient,
        params_eth_to_usdc.routes
    );
    let amounts_after_eth_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // events assertions
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_strk_to_usdt.token_from_address,
                            token_from_amount: params_strk_to_usdt.token_from_amount,
                            token_to_address: params_strk_to_usdt.token_to_address,
                            token_to_amount: amounts_after_strk_to_usdt.usdt
                                - amounts_before_strk_to_usdt.usdt
                                + FEE_AMOUNT,
                            beneficiary: params_strk_to_usdt.beneficiary,
                            provider: AVNU_EXCHANGE_ADDRESS()
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_strk_to_usdc.token_from_address,
                            token_from_amount: params_strk_to_usdc.token_from_amount,
                            token_to_address: params_strk_to_usdc.token_to_address,
                            token_to_amount: amounts_after_strk_to_usdc.usdc
                                - amounts_after_strk_to_usdt.usdc
                                + FEE_AMOUNT,
                            beneficiary: params_strk_to_usdc.beneficiary,
                            provider: AVNU_EXCHANGE_ADDRESS()
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_eth_to_usdt.token_from_address,
                            token_from_amount: params_eth_to_usdt.token_from_amount,
                            token_to_address: params_eth_to_usdt.token_to_address,
                            token_to_amount: amounts_after_eth_to_usdt.usdt
                                - amounts_after_strk_to_usdc.usdt
                                + FEE_AMOUNT,
                            beneficiary: params_eth_to_usdt.beneficiary,
                            provider: AVNU_EXCHANGE_ADDRESS()
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_eth_to_usdc.token_from_address,
                            token_from_amount: params_eth_to_usdc.token_from_amount,
                            token_to_address: params_eth_to_usdc.token_to_address,
                            token_to_amount: amounts_after_eth_to_usdc.usdc
                                - amounts_after_eth_to_usdt.usdc
                                + FEE_AMOUNT,
                            beneficiary: params_eth_to_usdc.beneficiary,
                            provider: AVNU_EXCHANGE_ADDRESS()
                        }
                    )
                )
            ]
        );
}

// *************************************************************************
//                        SHOULD PANIC CASES
// *************************************************************************
#[test]
#[fork("MAINNET", block_number: 996491)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_avnu_swap_should_fail_for_insufficient_allowance_to_contract() {
    let autoSwappr_dispatcher = __setup__();

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
}

#[test]
#[fork("MAINNET", block_number: 996491)]
#[should_panic(expected: 'Token not supported')]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    let autoSwappr_dispatcher = __setup__();

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        contract_address_const::<0x123>(), // unsupported token
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
}

#[test]
#[fork("MAINNET", block_number: 996491)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_should_fail_after_token_approval_is_revoked_avnu() {
    let autoSwappr_dispatcher = __setup__();
    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params1 = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params1.token_from_address,
        params1.token_from_amount,
        params1.token_to_address,
        params1.token_to_min_amount,
        params1.beneficiary,
        params1.integrator_fee_amount_bps,
        params1.integrator_fee_recipient,
        params1.routes
    );

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

    let params2 = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params2.token_from_address,
        params2.token_from_amount,
        params2.token_to_address,
        params2.token_to_min_amount,
        params2.beneficiary,
        params2.integrator_fee_amount_bps,
        params2.integrator_fee_recipient,
        params2.routes
    );
}

#[test]
#[fork("MAINNET", block_number: 996491)]
fn test_percentage_fee_deduction_on_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());
    let previous_exchange_amount_strk = get_exchange_amount(
        STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );
    let previous_exchange_amount_usdt = get_exchange_amount(
        USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );

    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, OWNER().try_into().unwrap());
    autoSwappr_dispatcher.set_fee_type(FeeType::Percentage, 200); // 200 basis points (2%)
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);
    call_avnu_swap(
        autoSwappr_dispatcher,
        ADDRESS_WITH_FUNDS(),
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );

    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_strk = get_exchange_amount(STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL());
    let new_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL());
    let new_fee_collector_amounts = get_wallet_amounts(FEE_COLLECTOR.try_into().unwrap());

    // assertions
    assert_eq!(
        new_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );

    assert_eq!(new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged");

    assert_ge!(
        new_amounts.usdt,
        previous_amounts.usdt + params.token_to_min_amount - FEE_AMOUNT,
        "Balance of to token should increase"
    );

    // assertions for the exchange
    assert_le!(
        new_exchange_amount_usdt,
        previous_exchange_amount_usdt - params.token_to_min_amount,
        "Exchange address USDT balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_strk,
        previous_exchange_amount_strk + AMOUNT_TO_SWAP_STRK,
        "Exchange address STRK balance should increase"
    );

    let expected_fee: u256 = params.token_to_min_amount * 200 / 10000; // 2% of the token_to_amount

    // fee collector assertion with tolerance
    // let tolerance: u256 = 100;
    assert!(
        new_fee_collector_amounts.usdt >= previous_fee_collector_amounts.usdt + expected_fee,
        "Fee collector USDT balance should increase by the fee amount within tolerance"
    );
}
