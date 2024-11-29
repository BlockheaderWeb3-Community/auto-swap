// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::syscalls::call_contract_syscall;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait
};

use auto_swappr::interfaces::autoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::Route;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


const USER_ONE: felt252 = 'JOE';
const USER_TWO: felt252 = 'DOE';
const OWNER: felt252 = 'OWNER';
const ONE_E18: u256 = 1000000000000000000_u256;

const FEE_COLLECTOR: felt252 = 0x02933d37493cc505b9b5fc635e1b3a111115d4e06391e2a5ada195e87ed57dbd;
const AVNU_EXCHANGE_ADDRESS: felt252 =
    0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f;
const STRK_TOKEN_ADDRESS: felt252 =
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const ETH_TOKEN_ADDRESS: felt252 =
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

const STK_MINTER_ADDRESS: felt252 =
    0x0594c1582459ea03f77deaf9eb7e3917d6994a03c13405ba42867f83d85f085d;
const SWAP_CALLER_ADDRESS: felt252 =
    0x058699dE9b95e692E974c043598C3827d921Af000004e887F476E52880A708d6;

const EKUBO_EXCHANGE_ADDRESS: felt252 =
    0x00000005dd3D2F4429AF886cD1a3b08289DBcEa99A294197E9eB43b0e0325b4b;

const ROUTE_PERCENT_FACTOR: u128 = 10000000000;


// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // deploy  events
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut auto_swappr_constructor_calldata: Array<felt252> = array![
        FEE_COLLECTOR, AVNU_EXCHANGE_ADDRESS, STRK_TOKEN_ADDRESS, ETH_TOKEN_ADDRESS
    ];

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@auto_swappr_constructor_calldata)
        .unwrap();

    auto_swappr_contract_address
}

#[test]
#[fork("Mainnet")]
fn test_swap() {
    let autoswappr_contract_address = __setup__();
    let autoswappr_contract = IAutoSwapprDispatcher {
        contract_address: autoswappr_contract_address
    };

    let strk_token_address = contract_address_const::<STRK_TOKEN_ADDRESS>();
    let minter_address = contract_address_const::<STK_MINTER_ADDRESS>();
    let caller = contract_address_const::<SWAP_CALLER_ADDRESS>();

    let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
    let mint_amount: u256 = 500 * ONE_E18;

    // Mint STRK to caller
    start_cheat_caller_address(strk_token_address, minter_address);
    let mut calldata: Array<felt252> = ArrayTrait::new();
    caller.serialize(ref calldata);
    mint_amount.serialize(ref calldata);
    call_contract_syscall(strk_token_address, selector!("permissioned_mint"), calldata.span())
        .unwrap();
    stop_cheat_caller_address(strk_token_address);
    assert(strk_token.balance_of(caller) == mint_amount, 'invalid balance');

    // Prank caller to approve auto_swapper
    start_cheat_caller_address(strk_token_address, caller);
    strk_token.approve(autoswappr_contract_address, mint_amount);
    stop_cheat_caller_address(strk_token_address);
    assert(
        strk_token.allowance(caller, autoswappr_contract_address) == mint_amount,
        'invalid allowance'
    );

    // Prank caller to and call swap() function in auto_swapper
    start_cheat_caller_address(autoswappr_contract_address, caller);
    let token_from_address = strk_token_address.clone();
    let token_from_amount: u256 = 400;
    let token_to_address = contract_address_const::<ETH_TOKEN_ADDRESS>();
    let token_to_amount: u256 = 1;
    let token_to_min_amount: u256 = 1;
    let beneficiary = caller.clone();
    let mut routes = ArrayTrait::new();

    routes
        .append(
            Route {
                token_from: token_from_address,
                token_to: token_to_address,
                exchange_address: contract_address_const::<EKUBO_EXCHANGE_ADDRESS>(),
                percent: 100 * ROUTE_PERCENT_FACTOR,
                additional_swap_params: ArrayTrait::new()
            }
        );

    autoswappr_contract
        .swap(
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_amount,
            token_to_min_amount,
            beneficiary,
            0,
            contract_address_const::<0x0>(),
            routes
        );
    stop_cheat_caller_address(autoswappr_contract_address);
}
