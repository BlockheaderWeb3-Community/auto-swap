// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, contract_address_const};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait
};

use crate::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use crate::base::types::{Route, Assets};
use crate::autoswappr::AutoSwappr::{Event, Subscribed};


const USER_ONE: felt252 = 'JOE';
const USER_TWO: felt252 = 'DOE';
// const OWNER: felt252 = 'OWNER';
// let OWNER: ContractAddress = contract_address_const::<'OWNER'>();

fn FEE_COLLECTOR() -> ContractAddress {
    'FEE_COLLECTOR'.try_into().unwrap()
}

// fn STRK_TOKEN() -> ContractAddress {
//     'strk_token'.try_into().unwrap()
// }

fn ETH_TOKEN() -> ContractAddress {
    'eth_token'.try_into().unwrap()
}

fn ANVU() -> ContractAddress {
    'avnu_exchange_address'.try_into().unwrap()
}

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, ContractAddress) {
    // deploy  events
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();
    let erc20_address = deploy_mock_erc20();

    let mut calldata = array![];

    FEE_COLLECTOR().serialize(ref calldata);
    ANVU().serialize(ref calldata);
    erc20_address.serialize(ref calldata);
    ETH_TOKEN().serialize(ref calldata);

    let (autoSwappr_contract_address, _) = autoSwappr_class_hash.deploy(@calldata).unwrap();

    (autoSwappr_contract_address, erc20_address)
}

fn deploy_mock_erc20() -> ContractAddress {
    let class_hash = declare("MockERC20").unwrap().contract_class();
    let mut calldata = array![];

    100_u256.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    let (address, _) = class_hash.deploy(@calldata).unwrap();

    address
}

#[test]
fn test_subscribe() {
    let (auto_swapper, erc20) = __setup__();
    let mut spy = spy_events();

    let auto_swapper_dispatcher = IAutoSwapprDispatcher { contract_address: auto_swapper };
    let mock_erc20 = deploy_mock_erc20();

    let asset = Assets { strk: true, eth: false };

    start_cheat_caller_address(auto_swapper, OWNER());
    auto_swapper_dispatcher.subscribe(asset);

    let expected_event = Event::Subscribed(
        Subscribed { user: OWNER(), assets: Assets { strk: true, eth: false }, }
    );

    spy.assert_emitted(@array![(auto_swapper_dispatcher.contract_address, expected_event)]);
}
