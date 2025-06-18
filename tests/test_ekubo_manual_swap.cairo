// snforge imports
use snforge_std::{
    start_cheat_caller_address_global, spy_events, EventSpyAssertionsTrait, cheat_caller_address,
    CheatSpan
};

use crate::constants::{
    STRK_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, ADDRESS_WITH_FUNDS, FEE_COLLECTOR,
    EKUBO_CORE_ADDRESS, STRK_TOKEN, FEE_AMOUNT, ETH_TOKEN_ADDRESS, SwapType
};

//autoSwappr imports
use auto_swappr::autoswappr::AutoSwappr::{Event, SwapSuccessful};
use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};


// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// ekubo imports
use ekubo::interfaces::core::{ILockerDispatcher, ILockerDispatcherTrait};
use ekubo::types::i129::i129;

use crate::utils::{mag_into, swap_param_util, __setup__};

#[test]
#[should_panic(expected: 'Amount is zero')]
fn test_should_revert_if_amount_in_is_zero() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 0, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[should_panic(expected: 'Token not supported')]
fn test_should_revert_if_token0_is_not_supported() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let mut swap_data = swap_param_util(SwapType::strk_usdc, amount);
    swap_data.pool_key.token0 = USDT_TOKEN_ADDRESS(); // unsupported token0
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_should_revert_if_allowance_is_insufficient() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);

    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    start_cheat_caller_address_global(ADDRESS_WITH_FUNDS());

    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount) - 1);
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: 'u256_sub Overflow')]
fn test_should_revert_if_amountIn_is_greater_than_user_balance() {
    let autoSwappr_dispatcher = __setup__();
    let balance = STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS());
    let amount = i129 { mag: balance.try_into().unwrap() + 1, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);

    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    start_cheat_caller_address_global(ADDRESS_WITH_FUNDS());
    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[should_panic(expected: 'CORE_ONLY')]
fn test_should_revert_if_another_address_apart_from_ekubo_core_calls_locked() {
    let autoSwappr_dispatcher = __setup__();
    let locker_dispatcher = ILockerDispatcher {
        contract_address: autoSwappr_dispatcher.contract_address,
    };
    let mock_id = 1;
    let mock_data = array!['mock_data'];
    locker_dispatcher.locked(mock_id, mock_data.span());
}


#[test]
#[fork("MAINNET")]
fn test_strk_for_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);

    let usdc = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    cheat_caller_address(strk.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));
    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

    let usdc_initial_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
    let strk_initial_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
    let mut spy = spy_events();
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);

    let usdc_final_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
    let strk_final_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
    let min_usdc_received = autoSwappr_dispatcher
        .get_token_amount_in_usd(strk.contract_address, 10.into())
        * 1_000_000;

    assert_eq!(strk_final_balance, strk_initial_balance - mag_into(amount));
    assert_ge!(usdc_final_balance, usdc_initial_balance + min_usdc_received - FEE_AMOUNT);
    assert_eq!(usdc.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: strk.contract_address,
                            token_to_address: usdc.contract_address,
                            token_from_amount: mag_into(amount),
                            token_to_amount: usdc_final_balance - usdc_initial_balance,
                            beneficiary: ADDRESS_WITH_FUNDS(),
                            provider: EKUBO_CORE_ADDRESS()
                        }
                    )
                )
            ]
        );
}


#[test]
#[fork("MAINNET")]
fn test_eth_for_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000, sign: false }; // 0.01 ETH

    let swap_data = swap_param_util(SwapType::eth_usdc, amount);

    let usdc = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
    let eth = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };
    cheat_caller_address(eth.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));
    eth.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

    let usdc_initial_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
    let eth_initial_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
    let mut spy = spy_events();
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);

    let usdc_final_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
    let eth_final_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
    let min_usdc_received = autoSwappr_dispatcher
        .get_token_amount_in_usd(eth.contract_address, 1.into())
        * 10_000; // convert 0.01 ETH to USD with 6 decimals
    let fee_offset = FEE_AMOUNT;
    assert_eq!(eth_final_balance, eth_initial_balance - mag_into(amount));
    assert_ge!(
        usdc_final_balance, usdc_initial_balance + min_usdc_received - FEE_AMOUNT - fee_offset
    );
    assert_eq!(usdc.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: eth.contract_address,
                            token_to_address: usdc.contract_address,
                            token_from_amount: mag_into(amount),
                            token_to_amount: usdc_final_balance - usdc_initial_balance,
                            beneficiary: ADDRESS_WITH_FUNDS(),
                            provider: EKUBO_CORE_ADDRESS()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET")]
fn test_strk_for_usdt_swap__only() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdt, amount);

    let usdt = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    cheat_caller_address(strk.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));
    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

    let usdt_initial_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
    let strk_initial_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
    let mut spy = spy_events();
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
    let usdt_final_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
    let strk_final_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
    let min_usdt_received = autoSwappr_dispatcher
        .get_token_amount_in_usd(strk.contract_address, 10.into())
        * 1_000_000;
    assert_eq!(strk_final_balance, strk_initial_balance - mag_into(amount));
    assert_ge!(usdt_final_balance, usdt_initial_balance + min_usdt_received - FEE_AMOUNT);
    assert_eq!(usdt.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: strk.contract_address,
                            token_to_address: usdt.contract_address,
                            token_from_amount: mag_into(amount),
                            token_to_amount: usdt_final_balance - usdt_initial_balance,
                            beneficiary: ADDRESS_WITH_FUNDS(),
                            provider: EKUBO_CORE_ADDRESS()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET")]
fn test_eth_for_usdt_swap() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000, sign: false }; // 0.01 ETH

    let swap_data = swap_param_util(SwapType::eth_usdt, amount);

    let usdt = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let eth = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };

    cheat_caller_address(eth.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));
    eth.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

    let usdt_initial_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
    let eth_initial_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
    let mut spy = spy_events();
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);

    let usdt_final_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
    let eth_final_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
    let min_usdt_received = autoSwappr_dispatcher
        .get_token_amount_in_usd(eth.contract_address, 1.into())
        * 10_000; // convert 0.01 ETH to USD with 6 decimals
    let fee_offset = FEE_AMOUNT;
    assert_eq!(eth_final_balance, eth_initial_balance - mag_into(amount));
    assert_ge!(
        usdt_final_balance, usdt_initial_balance + min_usdt_received - FEE_AMOUNT - fee_offset
    );
    assert_eq!(usdt.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: eth.contract_address,
                            token_to_address: usdt.contract_address,
                            token_from_amount: mag_into(amount),
                            token_to_amount: usdt_final_balance - usdt_initial_balance,
                            beneficiary: ADDRESS_WITH_FUNDS(),
                            provider: EKUBO_CORE_ADDRESS()
                        }
                    )
                )
            ]
        );
}
