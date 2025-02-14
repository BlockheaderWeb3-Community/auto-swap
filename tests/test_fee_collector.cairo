// *************************************************************************
//                              TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, start_cheat_block_timestamp, EventSpyAssertionsTrait
};

use auto_swappr::base::types::{Route, FeeType, Token};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait, IERC20};

use auto_swappr::interfaces::ifee_collector::{
    IFeeCollectorDispatcher, IFeeCollectorDispatcherTrait
};
use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};
use auto_swappr::interfaces::ierc20_mintable::{
    IERC20MintableDispatcher, IERC20MintableDispatcherTrait
};

// Contract Address Constants
pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

pub fn NEW_OPERATOR() -> ContractAddress {
    contract_address_const::<'NEW_OPERATOR'>()
}

pub fn NON_EXISTENT_OPERATOR() -> ContractAddress {
    contract_address_const::<'NON_EXISTENT_OPERATOR'>()
}

fn STRK_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

fn USDT_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x068F5c6a61780768455de69077E07e89787839bf8166dEcfBf92B645209c0fB8>()
}


// *************************************************************************
//                              SETUP
// *************************************************************************
fn deploy_fee_collector(
    strk_contract_address: ContractAddress, usdt_contract_address: ContractAddress
) -> ContractAddress {
    let fee_collector_class_hash = declare("FeeCollector").unwrap().contract_class();
    let mut fee_collector_constructor_calldata: Array<felt252> = array![];
    OWNER().serialize(ref fee_collector_constructor_calldata);
    strk_contract_address.serialize(ref fee_collector_constructor_calldata);
    usdt_contract_address.serialize(ref fee_collector_constructor_calldata);

    let (fee_collector_contract_address, _) = fee_collector_class_hash
        .deploy(@fee_collector_constructor_calldata)
        .unwrap();

    fee_collector_contract_address
}

fn __setup__() -> (ContractAddress, IFeeCollectorDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
    let strk_token_name: ByteArray = "STARKNET TOKEN";
    let strk_token_symbol: ByteArray = "STRK";
    let strk_token_decimals: u8 = 18;

    let usdt_token_name: ByteArray = "TETHER USD";
    let usdt_token_symbol: ByteArray = "USDT";
    let usdt_token_decimals: u8 = 6;

    let supply: u256 = 1_000_000_000_000_000_000;

    let erc20_class_hash = declare("ERC20Upgradeable").unwrap().contract_class();
    let mut strk_constructor_calldata = array![];
    strk_token_name.serialize(ref strk_constructor_calldata);
    strk_token_symbol.serialize(ref strk_constructor_calldata);
    strk_token_decimals.serialize(ref strk_constructor_calldata);
    // supply.serialize(ref strk_constructor_calldata);
    USER().serialize(ref strk_constructor_calldata);
    OWNER().serialize(ref strk_constructor_calldata);

    let (strk_contract_address, _) = erc20_class_hash.deploy(@strk_constructor_calldata).unwrap();

    let mut usdt_constructor_calldata = array![];
    usdt_token_name.serialize(ref usdt_constructor_calldata);
    usdt_token_symbol.serialize(ref usdt_constructor_calldata);
    usdt_token_decimals.serialize(ref usdt_constructor_calldata);
    // supply.serialize(ref usdt_constructor_calldata);
    USER().serialize(ref usdt_constructor_calldata);
    OWNER().serialize(ref usdt_constructor_calldata);

    let (usdt_contract_address, _) = erc20_class_hash.deploy(@usdt_constructor_calldata).unwrap();

    let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
    let usdt_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // deploy FeeCollector
    let fee_collector_contract_address = deploy_fee_collector(
        strk_contract_address, usdt_contract_address
    );

    start_cheat_caller_address(strk_contract_address, OWNER());
    let ERC20_mintable_dispatcher = IERC20MintableDispatcher {
        contract_address: strk_contract_address
    };
    ERC20_mintable_dispatcher.mint(fee_collector_contract_address, 1000.try_into().unwrap());
    stop_cheat_caller_address(OWNER());

    let fee_collector_dispatcher = IFeeCollectorDispatcher {
        contract_address: fee_collector_contract_address
    };

    let operator_dispatcher = IOperatorDispatcher {
        contract_address: fee_collector_contract_address
    };

    start_cheat_caller_address(fee_collector_contract_address, OWNER());
    operator_dispatcher.set_operator(OPERATOR());

    return (
        fee_collector_contract_address, fee_collector_dispatcher, strk_dispatcher, usdt_dispatcher
    );
}

#[test]
fn test_withdraw_strk_to_operator() {
    let (fee_collector_contract_address, fee_collector_dispatcher, strk_dispatcher, _) =
        __setup__();

    println!("Fee Collector Contract: {:?}", fee_collector_contract_address);

    let token = Token::STRK;

    let initial_fee_collector_strk_balance = fee_collector_dispatcher.get_token_balance(token);
    println!("Fee collector balance before: {}", initial_fee_collector_strk_balance);
    assert(initial_fee_collector_strk_balance == 1000.try_into().unwrap(), 'Incorrect balance');

    let operator_balance_before = strk_dispatcher.balance_of(OPERATOR());
    println!("Operator balance before: {}", operator_balance_before);

    start_cheat_caller_address(fee_collector_contract_address, OWNER());
    fee_collector_dispatcher.withdraw(OPERATOR(), 500.try_into().unwrap(), token);

    let operator_balance_after = strk_dispatcher.balance_of(OPERATOR());
    println!("Operator balance after: {}", operator_balance_after);

    let strk_balance_after = fee_collector_dispatcher.get_token_balance(token);
    println!("{}", strk_balance_after);
    assert(strk_balance_after == 500.try_into().unwrap(), 'Incorrect balance');
}

