// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, contract_address_const};
use starknet::syscalls::call_contract_syscall;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use crate::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use crate::base::types::Route;


const USER_ONE: felt252 = 'JOE';
const USER_TWO: felt252 = 'DOE';
const OWNER: felt252 = "OWNER";
const STRK_TOKEN_ADDRESS: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const SWAP_CALLER_ADDRESS: felt252 = 0x0594c1582459ea03f77deaf9eb7e3917d6994a03c13405ba42867f83d85f085d;

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

    autoSwappr_contract_address
}

#[test]
#[fork("Mainnet")]
fn test_swap() {
    let autoswappr_contract_address = __setup__();
    let autoswappr_contract = IAutoSwapprDispatcher { contract_address: autoswappr_contract_address }

    let strk_token_address = contract_address_const::<STRK_TOKEN_ADDRESS>();
    let caller = contract_address_const::<SWAP_CALLER_ADDRESS>();

    let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
}
