// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use crate::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use crate::base::types::Route;

// *************************************************************************
//                              CONSTANTS
// *************************************************************************
const USER_ONE: felt252 = 'JOE';
const USER_TWO: felt252 = 'DOE';
const OWNER: felt252 = "OWNER";

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // Deploy events
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![OWNER];
    let (autoSwappr_contract_address, _) = events_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return autoSwappr_contract_address;
}

// *************************************************************************
//                              Helper Functions
// *************************************************************************

/// Simulate the approval of a spender by a token contract.
fn approve_token(token_contract: ContractAddress, spender: ContractAddress, amount: u256) {
    let token_instance = IERC20Dispatcher { contract_address: token_contract };
    token_instance.approve(spender, amount);
}

/// Reset approval for a spender.
fn reset_approval(token_contract: ContractAddress, spender: ContractAddress) {
    let token_instance = IERC20Dispatcher { contract_address: token_contract };
    token_instance.approve(spender, u256 { low: 0, high: 0 });
}

// *************************************************************************
//                              TESTS
// *************************************************************************

#[test]
fn test_is_approved_success() {
    let autoSwappr_contract = __setup__();
    let token_contract = __setup__();

    let spender = autoSwappr_contract;

    // Approve 100 tokens for the spender
    approve_token(token_contract, spender, u256 { low: 100, high: 0 });

    // Check if approval is successful
    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(spender, token_contract);

    assert!(result, "is_approved should return true for valid approvals");
}

#[test]
fn test_is_approved_failure() {
    let autoSwappr_contract = __setup__();
    let token_contract = __setup__();

    let spender = autoSwappr_contract;

    // Reset approval to zero
    reset_approval(token_contract, spender);

    // Check if approval is denied
    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(spender, token_contract);

    assert!(!result, "is_approved should return false when no approval is set");
}

#[test]
fn test_is_approved_partial_allowance() {
    let autoSwappr_contract = __setup__();
    let token_contract = __setup__();

    let spender = autoSwappr_contract;

    // Approve a partial amount
    approve_token(token_contract, spender, u256 { low: 0, high: 1 });

    // Check if approval is recognized
    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(spender, token_contract);

    assert!(result, "is_approved should return true when allowance.high > 0");
}

#[test]
fn test_is_approved_invalid_addresses() {
    let autoSwappr_contract = __setup__();
    let token_contract = ContractAddress::from(0); // Invalid token address
    let spender = autoSwappr_contract;

    // Check if invalid addresses are handled correctly
    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(spender, token_contract);

    assert!(!result, "is_approved should return false for invalid token contract addresses");
}
