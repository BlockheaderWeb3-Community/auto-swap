// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};

use snforge_std::{
    declare, start_cheat_caller_address, start_cheat_block_timestamp, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait
};

use auto_swappr::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::Assets;
use auto_swappr::autoswappr::AutoSwappr;
use auto_swappr::base::errors::Errors;

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

const USER: felt252 = 'USER';
const OWNER: felt252 = 'OWNER';
const AVNU_ADDR: felt252 = 'AVNU';
const FEE_COLLECTOR_ADDR: felt252 = 'FEE_COLLECTOR';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IERC20Dispatcher, IERC20Dispatcher) {
    let STRK: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let ETH: ContractAddress = 0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();

    let strk_dispatcher = IERC20Dispatcher { contract_address: STRK };
    let eth_dispatcher = IERC20Dispatcher { contract_address: ETH };

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

    return (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher);
}

#[test]
#[should_panic(expected: 'Caller cannot be zero addr')]
fn test_unsubscribe_zero_addr() {
    let (autoSwappr_contract_address, _, _) = __setup__();
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
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let mut spy = spy_events();

    let user_addr: ContractAddress = USER.try_into().unwrap();
    let assets: Assets = Assets { strk: true, eth: true };

    let timestamp: u64 = 343000;
    start_cheat_block_timestamp(autoSwappr_contract_address.try_into().unwrap(), timestamp);
    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);

    let strk_allowance = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_allowance = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    assert(strk_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);
    assert(eth_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);

    autoSwappr_dispatcher.subscribe(assets.clone());

    let strk_before = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_before = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    autoSwappr_dispatcher.unsubscribe(assets.clone());

    let strk_after = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_after = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    assert(strk_after == strk_before, Errors::STRK_UNSUBSCRIBED);
    assert(eth_after == eth_before, Errors::ETH_UNSUBSCRIBED);

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed {
                            user: user_addr, assets, block_timestamp: timestamp
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_eth() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress = USER.try_into().unwrap();
    let assets: Assets = Assets { strk: true, eth: false };

    let timestamp: u64 = 343000;
    start_cheat_block_timestamp(autoSwappr_contract_address.try_into().unwrap(), timestamp);
    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);

    let strk_allowance = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_allowance = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    assert(strk_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);
    assert(eth_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);

    autoSwappr_dispatcher.subscribe(assets.clone());

    let strk_before = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    autoSwappr_dispatcher.unsubscribe(assets.clone());

    let strk_after = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_after = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    assert(strk_after == strk_before, Errors::STRK_UNSUBSCRIBED);
    assert(eth_after == 0, Errors::ETH_NOT_UNSUBSCRIBED);

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed {
                            user: user_addr, assets, block_timestamp: timestamp
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_strk() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress = USER.try_into().unwrap();
    let assets: Assets = Assets { strk: false, eth: true };

    let timestamp: u64 = 343000;
    start_cheat_block_timestamp(autoSwappr_contract_address.try_into().unwrap(), timestamp);
    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);

    let strk_allowance = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_allowance = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    assert(strk_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);
    assert(eth_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);

    autoSwappr_dispatcher.subscribe(assets.clone());

    let eth_before = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    autoSwappr_dispatcher.unsubscribe(assets.clone());

    let strk_after = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_after = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    assert(strk_after == 0, Errors::STRK_NOT_UNSUBSCRIBED);
    assert(eth_after == eth_before, Errors::ETH_UNSUBSCRIBED);

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed {
                            user: user_addr, assets, block_timestamp: timestamp
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_unsubscribe_all() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let mut spy = spy_events();

    let user_addr: ContractAddress = USER.try_into().unwrap();
    let assets: Assets = Assets { strk: false, eth: false };

    let timestamp: u64 = 343000;
    start_cheat_block_timestamp(autoSwappr_contract_address.try_into().unwrap(), timestamp);
    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), user_addr);

    let strk_allowance = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_allowance = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    assert(strk_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);
    assert(eth_allowance == 0, Errors::ALLOWANCE_NOT_ZERO);

    autoSwappr_dispatcher.subscribe(assets.clone());
    autoSwappr_dispatcher.unsubscribe(assets.clone());

    let strk_after = strk_dispatcher.allowance(user_addr, autoSwappr_contract_address);
    let eth_after = eth_dispatcher.allowance(user_addr, autoSwappr_contract_address);

    assert(strk_after == 0, Errors::STRK_NOT_UNSUBSCRIBED);
    assert(eth_after == 0, Errors::ETH_NOT_UNSUBSCRIBED);

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    AutoSwappr::Event::Unsubscribed(
                        AutoSwappr::Unsubscribed {
                            user: user_addr, assets, block_timestamp: timestamp
                        }
                    )
                )
            ]
        );
}
