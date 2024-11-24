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

use auto_swappr::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{Route, Assets};


const USER_ONE: felt252 = 'JON';
const USER_TWO: felt252 = 'DOE';
const USER_THREE: felt252 = 'USER';
const OWNER: felt252 = 'OWNER';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // deploy  events
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![OWNER, USER_ONE, USER_TWO];
    let (autoSwappr_contract_address, _) = autoSwappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return (autoSwappr_contract_address);
}

#[test]
#[should_panic(expected: 'Caller cannot be zero addr')]
fn test_unsubscribe_zero_addr() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher { contract_address: autoSwappr_contract_address };

    let zero_addr: ContractAddress = 0x0000000000000000000000000000000000000000000000000000000000000000.try_into().unwrap();
    let assets: Assets = Assets { strk: true, eth: true };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), zero_addr);
    autoSwappr_dispatcher.unsubscribe(assets);
}

#[test]
fn test_unsubscribe() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher { contract_address: autoSwappr_contract_address };

    let user_addr: ContractAddress = USER_THREE.try_into().unwrap();
    let assets: Assets = Assets { strk: true, eth: true };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);
    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets);
}