// *************************************************************************
//                              TEST
// *************************************************************************
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

// Contract Address Constants
pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}

pub fn OWNER() -> ContractAddress {
    contract_address_const::<0x01d6abf4f5963082fc6c44d858ac2e89434406ed682fb63155d146c5d69c22d6>()
}

pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<0x02fB08aaf620D1a045FBbd0F56a795b1c7fF88B63DDa22028870A48f9a92F4FA>()
}

fn FEE_COLLECTOR_ADDRESS() -> ContractAddress {
    contract_address_const::<0x02977ce390254822db6d57f71e42180d05e08a9e4f66abe7f3f509f7132eb840>()
}

fn STRK_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

fn USDT_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x068F5c6a61780768455de69077E07e89787839bf8166dEcfBf92B645209c0fB8>()
}

fn STRK_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() }
}

fn USDT_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() }
}

fn FEE_COLLECTOR() -> IFeeCollectorDispatcher {
    IFeeCollectorDispatcher { contract_address: FEE_COLLECTOR_ADDRESS() }
}

fn OPERATOR_DISPATCHER() -> IOperatorDispatcher {
    IOperatorDispatcher { contract_address: FEE_COLLECTOR_ADDRESS() }
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
#[fork("SEPOLIA_LATEST")]
fn test_set_operator() {
    set_operator(OWNER(), OPERATOR());

    let is_operator = OPERATOR_DISPATCHER().is_operator(OPERATOR());
    assert(is_operator, 'Operator not add');
}

#[test]
#[fork("SEPOLIA_LATEST")]
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
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_operator_not_owner() {
    set_operator(USER(), OPERATOR());
}

#[test]
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('address already exist',))]
fn test_set_operator_already_exists() {
    set_operator(OWNER(), OPERATOR());
    set_operator(OWNER(), OPERATOR());
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_remove_operator() {
    set_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());

    let is_operator = OPERATOR_DISPATCHER().is_operator(OPERATOR());
    assert(!is_operator, 'Operator not removed');
}

#[test]
#[fork("SEPOLIA_LATEST")]
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
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_operator_not_owner() {
    remove_operator(USER(), OPERATOR());
}

#[test]
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('address does not exist',))]
fn test_remove_operator_not_exists() {
    set_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());
    remove_operator(OWNER(), OPERATOR());
}

#[test]
#[fork("SEPOLIA_LATEST")]
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
        operator_strk_balance_after == initial_operator_strk_balance + 500, 'Incorrect strk balance'
    );

    let fee_collector_strk_balance_after = FEE_COLLECTOR().get_token_balance(token);
    assert(
        fee_collector_strk_balance_after == initial_fee_collector_strk_balance - 500,
        'Incorrect strk balance'
    );
}

#[test]
#[fork("SEPOLIA_LATEST")]
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
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('Address is not an operator',))]
fn test_withdraw_strk_to_not_operator() {
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
}

#[test]
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_withdraw_strk_to_not_owner() {
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), USER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 500_u256, token);
}

#[test]
#[fork("SEPOLIA_LATEST")]
#[should_panic(expected: ('Insufficient Balance',))]
fn test_withdraw_strk_insufficient_balance() {
    set_operator(OWNER(), OPERATOR());
    let token = 'STRK';

    start_cheat_caller_address(FEE_COLLECTOR_ADDRESS(), OWNER());
    FEE_COLLECTOR().withdraw(OPERATOR(), 900000000000000000000_u256, token);
}

