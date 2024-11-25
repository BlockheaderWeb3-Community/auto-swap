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
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait, EventSpyTrait, EventsFilterTrait,
    EventSpy
};

use auto_swappr::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{Route, Assets};
use auto_swappr::autoswappr::AutoSwappr;


const USER_ONE: felt252 = 'JON';
const USER_TWO: felt252 = 'DOE';
const USER_THREE: felt252 = 'USER';
const OWNER: felt252 = 'OWNER';
const AVNU_ADDR: felt252 = 'AVNU';
const FEE_COLLECTOR_ADDR: felt252 = 'FEE_COLLECTOR';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    let STRK: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let ETH: ContractAddress = 0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();

    let STRK_FELT: felt252 = STRK.into();
    let ETH_FELT: felt252 = ETH.into();

    // deploy  events
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![
        OWNER, AVNU_ADDR, STRK_FELT, ETH_FELT
    ];
    let (autoSwappr_contract_address, _) = autoSwappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return (autoSwappr_contract_address);
}

#[test]
#[should_panic(expected: 'Caller cannot be zero addr')]
fn test_unsubscribe_zero_addr() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let zero_addr: ContractAddress =
        0x0000000000000000000000000000000000000000000000000000000000000000
        .try_into()
        .unwrap();
    let assets: Assets = Assets { strk: true, eth: true };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), zero_addr);
    autoSwappr_dispatcher.unsubscribe(assets);
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_none() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress = USER_THREE.try_into().unwrap();
    let assets: Assets = Assets { strk: false, eth: false };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);
    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets.clone());

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed { user: user_addr, assets }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_eth() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress =
        0x20281104e6cb5884dabcdf3be376cf4ff7b680741a7bb20e5e07c26cd4870af
        .try_into()
        .unwrap();
    let assets: Assets = Assets { strk: false, eth: true };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);
    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets.clone());

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed { user: user_addr, assets }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_strk() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress =
        0x20281104e6cb5884dabcdf3be376cf4ff7b680741a7bb20e5e07c26cd4870af
        .try_into()
        .unwrap();
    let assets: Assets = Assets { strk: true, eth: false };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);
    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets.clone());

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed { user: user_addr, assets }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_all() {
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress =
        0x20281104e6cb5884dabcdf3be376cf4ff7b680741a7bb20e5e07c26cd4870af
        .try_into()
        .unwrap();
    let assets: Assets = Assets { strk: true, eth: true };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);
    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets.clone());

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed { user: user_addr, assets }
                    )
                )
            ]
        );
}
