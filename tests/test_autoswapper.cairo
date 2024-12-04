// *************************************************************************
//                              TEST
// *************************************************************************
use core::result::ResultTrait;
use core::option::OptionTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    start_cheat_caller_address_global, stop_cheat_caller_address_global, EventSpyTrait, spy_events,
};

use auto_swappr::interfaces::iautoswappr::{
    IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait, ContractInfo,
};
use auto_swappr::base::types::Route;

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::upgrades::interface::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};

// *************************************************************************
//                              CONSTANTS
// *************************************************************************
pub fn ZERO() -> ContractAddress {
    contract_address_const::<0>()
}
pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
pub fn FEE_COLLECTOR_ADDR() -> ContractAddress {
    contract_address_const::<'FEE_COLLECTOR_ADDR'>()
}
pub fn AVNU_ADDR() -> ContractAddress {
    contract_address_const::<'AVNU_ADDR'>()
}
pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IERC20Dispatcher, IERC20Dispatcher) {
    // ERC20 and AutoSwappr setup
    let strk_token_name: ByteArray = "STARKNET_TOKEN";
    let strk_token_symbol: ByteArray = "STRK";
    let supply: u256 = 1_000_000_000_000_000_000;

    let eth_token_name: ByteArray = "ETHER";
    let eth_token_symbol: ByteArray = "ETH";

    let erc20_class_hash = declare("ERC20Upgradeable").unwrap().contract_class();

    // Deploy STRK token
    let mut strk_constructor_calldata = array![];
    strk_token_name.serialize(ref strk_constructor_calldata);
    strk_token_symbol.serialize(ref strk_constructor_calldata);
    supply.serialize(ref strk_constructor_calldata);
    USER().serialize(ref strk_constructor_calldata);
    OWNER().serialize(ref strk_constructor_calldata);
    let (strk_contract_address, _) = erc20_class_hash.deploy(@strk_constructor_calldata).unwrap();

    // Deploy ETH token
    let mut eth_constructor_calldata = array![];
    eth_token_name.serialize(ref eth_constructor_calldata);
    eth_token_symbol.serialize(ref eth_constructor_calldata);
    supply.serialize(ref eth_constructor_calldata);
    USER().serialize(ref eth_constructor_calldata);
    OWNER().serialize(ref eth_constructor_calldata);
    let (eth_contract_address, _) = erc20_class_hash.deploy(@eth_constructor_calldata).unwrap();

    // Deploy AutoSwappr
    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();
    let mut autoSwappr_constructor_calldata: Array<felt252> = array![];
    FEE_COLLECTOR_ADDR().serialize(ref autoSwappr_constructor_calldata);
    AVNU_ADDR().serialize(ref autoSwappr_constructor_calldata);
    strk_contract_address.serialize(ref autoSwappr_constructor_calldata);
    eth_contract_address.serialize(ref autoSwappr_constructor_calldata);
    OWNER().serialize(ref autoSwappr_constructor_calldata);
    let (autoSwappr_contract_address, _) = autoSwappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return (
        autoSwappr_contract_address,
        IERC20Dispatcher { contract_address: strk_contract_address },
        IERC20Dispatcher { contract_address: eth_contract_address }
    );
}

// *************************************************************************
//                              HELPER FUNCTIONS
// *************************************************************************

fn approve_token(token_contract: ContractAddress, spender: ContractAddress, amount: u256) {
    start_cheat_caller_address_global(USER());
    let token_instance = IERC20Dispatcher { contract_address: token_contract };
    let result = token_instance.approve(spender, amount);
    assert(result, 'Token approval failed'.into());
    stop_cheat_caller_address_global();
}

fn reset_approval(token_contract: ContractAddress, spender: ContractAddress) {
    start_cheat_caller_address_global(USER());
    let token_instance = IERC20Dispatcher { contract_address: token_contract };
    token_instance.approve(spender, u256 { low: 0, high: 0 });
    stop_cheat_caller_address_global();
}

// *************************************************************************
//                              TESTS
// *************************************************************************

#[test]
fn test_is_approved_success() {
    let (autoSwappr_contract, token_dispatcher, _) = __setup__();
    let spender = autoSwappr_contract;

    let valid_amount = u256 { low: 100, high: 0 };
    approve_token(token_dispatcher.contract_address, spender, valid_amount);

    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(USER(), token_dispatcher.contract_address);

    assert!(result, "is_approved should return true for valid approvals");
}

#[test]
fn test_is_approved_failure() {
    let (autoSwappr_contract, token_dispatcher, _) = __setup__();
    let spender = autoSwappr_contract;

    reset_approval(token_dispatcher.contract_address, spender);

    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(spender, token_dispatcher.contract_address);

    assert!(!result, "is_approved should return false when no approval is set");
}

#[test]
fn test_is_approved_partial_allowance() {
    let (autoSwappr_contract, token_dispatcher, _) = __setup__();
    let spender = autoSwappr_contract;

    let partial_amount = u256 { low: 0, high: 1 };
    approve_token(token_dispatcher.contract_address, spender, partial_amount);

    let result = IAutoSwapprDispatcher { contract_address: autoSwappr_contract }
        .is_approved(USER(), token_dispatcher.contract_address);

    assert!(result, "is_approved should return true when allowance.high > 0");
}

#[test]
#[should_panic(expected: 'Caller is the zero address')]
fn test_zero_addr_upgrade() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let upgradeable_dispatcher = IUpgradeableDispatcher {
        contract_address: autoSwappr_contract_address,
    };

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), ZERO());

    let autoSwappr_contract_class = declare("AutoSwappr").unwrap().contract_class();
    let autoSwappr_class_hash = autoSwappr_contract_class.class_hash;

    upgradeable_dispatcher.upgrade(*autoSwappr_class_hash);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_not_owner_upgrade() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let upgradeable_dispatcher = IUpgradeableDispatcher {
        contract_address: autoSwappr_contract_address,
    };

    let autoSwappr_contract_class = declare("AutoSwappr").unwrap().contract_class();
    let autoSwappr_class_hash = autoSwappr_contract_class.class_hash;

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), USER());

    upgradeable_dispatcher.upgrade(*autoSwappr_class_hash);
}

#[test]
fn test_upgrade() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let upgradeable_dispatcher = IUpgradeableDispatcher {
        contract_address: autoSwappr_contract_address,
    };

    let autoSwappr_contract_class = declare("AutoSwappr").unwrap().contract_class();
    let autoSwappr_class_hash = autoSwappr_contract_class.class_hash;

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), OWNER());

    let mut spy = spy_events();

    upgradeable_dispatcher.upgrade(*autoSwappr_class_hash);

    let events = spy.get_events();

    assert(events.events.len() == 1, 'There should be one event');

    let (from, event) = events.events.at(0);
    assert(from == @autoSwappr_contract_address, 'Emitted from wrong address');
    assert(event.keys.len() == 1, 'There should be one key');
    assert(event.keys.at(0) == @selector!("Upgraded"), 'Wrong event name');
    assert(event.data.len() == 1, 'There should be one data');
}

#[test]
fn test_constructor_initializes_correctly() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address,
    };
    let expected_contract_parameters = ContractInfo {
        fees_collector: FEE_COLLECTOR_ADDR(),
        avnu_exchange_address: AVNU_ADDR(),
        strk_token: strk_dispatcher.contract_address,
        eth_token: eth_dispatcher.contract_address,
        owner: OWNER(),
    };
    let actual_contract_parameters = autoSwappr_dispatcher.contract_parameters();
    assert_eq!(expected_contract_parameters, actual_contract_parameters);
}
#[test]
#[should_panic(expected: 'Amount is zero')]
fn test_swap_reverts_if_token_from_amount_is_zero() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

    let token_from_address: ContractAddress = strk_dispatcher.contract_address;
    let token_from_amount: u256 = 0;
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();

    start_cheat_caller_address_global(USER());

    autoSwappr_dispatcher
        .swap(
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_amount,
            token_to_min_amount,
            beneficiary,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            routes,
        );

    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Token not supported')]
fn test_swap_reverts_if_token_is_not_supported() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

    let token_from_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER());
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();

    start_cheat_caller_address_global(USER());

    autoSwappr_dispatcher
        .swap(
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_amount,
            token_to_min_amount,
            beneficiary,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            routes,
        );

    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Insufficient Balance')]
fn test_swap_reverts_if_user_balance_is_lesser_than_swap_amount() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

    let token_from_address: ContractAddress = strk_dispatcher.contract_address;
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER())
        * 2; // swap amount exceeds balance
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();

    start_cheat_caller_address_global(USER());

    autoSwappr_dispatcher
        .swap(
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_amount,
            token_to_min_amount,
            beneficiary,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            routes,
        );

    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_reverts_if_user_allowance_to_contract_is_lesser_than_swap_amount() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };

    let token_from_address: ContractAddress = strk_dispatcher.contract_address;
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER());
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();

    // no approval to the autoSwappr contract
    start_cheat_caller_address_global(USER());

    autoSwappr_dispatcher
        .swap(
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_amount,
            token_to_min_amount,
            beneficiary,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            routes,
        );

    stop_cheat_caller_address_global();
}
