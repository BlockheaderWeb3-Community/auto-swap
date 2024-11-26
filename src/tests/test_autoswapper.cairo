// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, ClassHash};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use crate::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use crate::base::types::Route;


const USER_ONE: felt252 = 'JOE';
const USER_TWO: felt252 = 'DOE';
const OWNER: felt252 = "OWNER";

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // deploy  events
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![OWNER];
    let (autoSwappr_contract_address, _) = events_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return (autoSwappr_contract_address);
}

#[test]
#[should_panic(expected: 'Only Owner can call the upgradea function')]
fn test_only_owner_can_call_upgradeable_function() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    // Test only owner can call the upgradeable function
    let zero_addr: ContractAddress =
        0x0000000000000000000000000000000000000000000000000000000000000000
        .try_into()
        .unwrap();

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), zero_addr);
    let new_class_hash: ClassHash = ClassHash
    autoSwappr_dispatcher.upgrade(new_class_hash);
}

#[test]
fn test_upgrade_function_wroks() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let owner_address: ContractAddress = OWNER.try_into().unwrap();
    let autoswappr_address: ContractAddress = get_caller_address();
    assert_eq!(autoswappr_address == owner_address, "Only owner is authorize to upgrade contract");
    let new_class_hash: ClassHash = ClassHash

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), owner_address);
    autoSwappr_dispatcher.upgrade(new_class_hash);
}
}