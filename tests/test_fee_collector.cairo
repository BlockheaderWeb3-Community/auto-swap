// *************************************************************************
//                              TEST
// *************************************************************************

use crate::constants::{FEE_COLLECTOR_ADDRESS, STRK_TOKEN, USER, OPERATOR_DISPATCHER, OPERATOR};

// starknet imports
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

// snforge imports
use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
};

// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Autoswappr imports
use auto_swappr::fee_collector::FeeCollector;
use auto_swappr::components::operator::OperatorComponent;
use auto_swappr::interfaces::ifee_collector::{
    IFeeCollectorDispatcher, IFeeCollectorDispatcherTrait
};
use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};


pub fn OWNER() -> ContractAddress {
    contract_address_const::<0x01d6abf4f5963082fc6c44d858ac2e89434406ed682fb63155d146c5d69c22d6>()
}

fn FEE_COLLECTOR() -> IFeeCollectorDispatcher {
    IFeeCollectorDispatcher { contract_address: FEE_COLLECTOR_ADDRESS() }
}


fn set_operator(owner: ContractAddress, operator: ContractAddress) {
    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), owner);
    OPERATOR_DISPATCHER().set_operator(operator);
    stop_cheat_caller_address(owner);
}

fn remove_operator(owner: ContractAddress, operator: ContractAddress) {
    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), owner);
    OPERATOR_DISPATCHER().remove_operator(operator);
    stop_cheat_caller_address(owner);
}

#[test]
#[fork("MAINNET")]
fn test_set_operator() {
    set_operator(OWNER(), OPERATOR());

    let is_operator = OPERATOR_DISPATCHER().is_operator(OPERATOR());
    assert(is_operator, 'Operator not added');
}

#[test]
#[fork("MAINNET")]
fn test_set_operator_event() {
    let mut spy = spy_events();

    set_operator(OWNER(), OPERATOR());

    spy
        .assert_emitted(
            @array![
                (
                    FEE_COLLECTOR_ADDRESS(),
                    OperatorComponent::Event::OperatorAdded(
                        OperatorComponent::OperatorAdded {
                            operator: OPERATOR(), time_added: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_operator_not_owner() {
    set_operator(USER(), OPERATOR());
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('address already exist',))]
fn test_set_operator_already_exists() {
    set_operator(OWNER(), OPERATOR());
    set_operator(OWNER(), OPERATOR());
}

#[test]
#[fork("MAINNET")]
fn test_remove_operator() {
    set_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());

    let is_operator = OPERATOR_DISPATCHER().is_operator(OPERATOR());
    assert(!is_operator, 'Operator not removed');
}

#[test]
#[fork("MAINNET")]
fn test_remove_operator_event() {
    let mut spy = spy_events();

    set_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());

    spy
        .assert_emitted(
            @array![
                (
                    FEE_COLLECTOR_ADDRESS(),
                    OperatorComponent::Event::OperatorRemoved(
                        OperatorComponent::OperatorRemoved {
                            operator: OPERATOR(), time_removed: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_operator_not_owner() {
    remove_operator(USER(), OPERATOR());
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('address does not exist',))]
fn test_remove_operator_not_exists() {
    set_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());
}

#[test]
#[fork("MAINNET")]
fn test_withdraw_strk_to_operator() {
    set_operator(OWNER(), OPERATOR());

    let token = 'STRK';

    let initial_fee_collector_strk_balance = FEE_COLLECTOR().get_token_balance(token);
    let initial_operator_strk_balance = STRK_TOKEN().balance_of(OPERATOR());

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
    stop_cheat_caller_address(OWNER());

    let operator_strk_balance_after = STRK_TOKEN().balance_of(OPERATOR());
    assert(
        operator_strk_balance_after == initial_operator_strk_balance + 500_u256,
        'Incorrect strk balance'
    );

    let fee_collector_strk_balance_after = FEE_COLLECTOR().get_token_balance(token);
    assert(
        fee_collector_strk_balance_after == initial_fee_collector_strk_balance - 500_u256,
        'Incorrect strk balance'
    );
}

#[test]
#[fork("MAINNET")]
fn test_withdraw_strk_to_operator_event() {
    set_operator(OWNER(), OPERATOR());

    let mut spy = spy_events();

    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
    stop_cheat_caller_address(OWNER());

    spy
        .assert_emitted(
            @array![
                (
                    FEE_COLLECTOR_ADDRESS(),
                    FeeCollector::Event::FeesWithdrawn(
                        FeeCollector::FeesWithdrawn {
                            address: OPERATOR(), amount: 500_u256, timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Address is not an operator',))]
fn test_withdraw_strk_to_not_operator() {
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_withdraw_strk_to_not_owner() {
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), USER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Insufficient Balance',))]
fn test_withdraw_strk_insufficient_balance() {
    set_operator(OWNER(), OPERATOR());
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 900000000000000000000_u256, token);
}

