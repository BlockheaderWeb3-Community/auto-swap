// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global, spy_events, start_cheat_block_timestamp,
    EventSpyAssertionsTrait
};

use auto_swappr::interfaces::iautoswappr::{
    IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait, ContractInfo
};
use auto_swappr::base::types::{Route};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use auto_swappr::autoswappr::AutoSwappr::{Event, OperatorAdded, OperatorRemoved, FeeTypeChanged};

// Contract Address Constants
pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
pub fn FEE_COLLECTOR_ADDR() -> ContractAddress {
    contract_address_const::<'FEE_COLLECTOR_ADDR'>()
}

pub fn AVNU_ADDR() -> ContractAddress {
    contract_address_const::<'AVNU_ADDR'>()
}
pub fn FIBROUS_ADDR() -> ContractAddress {
    contract_address_const::<'FIBROUS_ADDR'>()
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
pub fn RANDOM_TOKEN() -> ContractAddress {
    contract_address_const::<'RANDOM_TOKEN'>()
}
pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}
pub fn NON_EXISTENT_OPERATOR() -> ContractAddress {
    contract_address_const::<'NON_EXISTENT_OPERATOR'>()
}

pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}

const FEE_AMOUNT_BPS: u8 = 50; // $0.5 fee

const INITIAL_FEE_TYPE: u8 = 0;
const INITIAL_PERCENTAGE_FEE:u16 = 100;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IERC20Dispatcher, IERC20Dispatcher) {
    let strk_token_name: ByteArray = "STARKNET_TOKEN";

    let strk_token_symbol: ByteArray = "STRK";
    let supply: u256 = 1_000_000_000_000_000_000;

    let eth_token_name: ByteArray = "ETHER";
    let eth_token_symbol: ByteArray = "ETH";

    let erc20_class_hash = declare("ERC20Upgradeable").unwrap().contract_class();
    let mut strk_constructor_calldata = array![];
    strk_token_name.serialize(ref strk_constructor_calldata);
    strk_token_symbol.serialize(ref strk_constructor_calldata);
    supply.serialize(ref strk_constructor_calldata);
    USER().serialize(ref strk_constructor_calldata);
    OWNER().serialize(ref strk_constructor_calldata);

    let (strk_contract_address, _) = erc20_class_hash.deploy(@strk_constructor_calldata).unwrap();

    let mut eth_constructor_calldata = array![];
    eth_token_name.serialize(ref eth_constructor_calldata);
    eth_token_symbol.serialize(ref eth_constructor_calldata);
    supply.serialize(ref eth_constructor_calldata);
    USER().serialize(ref eth_constructor_calldata);
    OWNER().serialize(ref eth_constructor_calldata);

    let (eth_contract_address, _) = erc20_class_hash.deploy(@eth_constructor_calldata).unwrap();

    let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
    let eth_dispatcher = IERC20Dispatcher { contract_address: eth_contract_address };

    // deploy AutoSwappr
    let autoSwappr_contract_address = deploy_autoSwappr(
        array![eth_contract_address, strk_contract_address], array!['ETH/USD', 'STRK/USD']
    );

    return (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher);
}

fn deploy_autoSwappr(
    supported_assets: Array<ContractAddress>, supported_assets_priceFeeds_ids: Array<felt252>
) -> ContractAddress {
    let autoswappr_class_hash = declare("AutoSwappr").unwrap().contract_class();
    let mut autoSwappr_constructor_calldata: Array<felt252> = array![];
    FEE_COLLECTOR_ADDR().serialize(ref autoSwappr_constructor_calldata);
    FEE_AMOUNT_BPS.serialize(ref autoSwappr_constructor_calldata);
    AVNU_ADDR().serialize(ref autoSwappr_constructor_calldata);
    FIBROUS_ADDR().serialize(ref autoSwappr_constructor_calldata);
    ORACLE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    supported_assets.serialize(ref autoSwappr_constructor_calldata);
    supported_assets_priceFeeds_ids.serialize(ref autoSwappr_constructor_calldata);
    OWNER().serialize(ref autoSwappr_constructor_calldata);
    INITIAL_FEE_TYPE.serialize(ref autoSwappr_constructor_calldata);
    INITIAL_PERCENTAGE_FEE.serialize(ref autoSwappr_constructor_calldata);
    let (autoSwappr_contract_address, _) = autoswappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_operator(OPERATOR());
    autoSwappr_contract_address
}

#[test]
#[should_panic]
fn test_constructor_reverts_if_supported_assets_array_is_empty() {
    deploy_autoSwappr(array![], array!['ETH/USD', 'STRK/USD']);
}

#[test]
#[should_panic]
fn test_constructor_reverts_if_supported_assets_array_length_doesnt_match_priceFeedId_array_length() {
    let eth_contract_address: ContractAddress = contract_address_const::<'ETH_TOKEN_ADDRESS'>();
    let strk_contract_address: ContractAddress = contract_address_const::<'STRK_TOKEN_ADDRESS'>();
    let wbtc_contract_address: ContractAddress = contract_address_const::<'WBTC_TOKEN_ADDRESS'>();
    let supported_assets = array![
        eth_contract_address, strk_contract_address, wbtc_contract_address
    ];
    deploy_autoSwappr(supported_assets, array!['ETH/USD', 'STRK/USD']);
}

#[test]
fn test_constructor_initializes_correctly() {
    let (autoSwappr_contract_address, _, _,) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let expected_contract_params = ContractInfo {
        fees_collector: FEE_COLLECTOR_ADDR(),
        fibrous_exchange_address: FIBROUS_ADDR(),
        avnu_exchange_address: AVNU_ADDR(),
        oracle_address: ORACLE_ADDRESS(),
        owner: OWNER(),
        fee_type: INITIAL_FEE_TYPE,
        percentage_fee: INITIAL_PERCENTAGE_FEE
    };
    let actual_contract_params = autoswappr_dispatcher.contract_parameters();
    assert_eq!(expected_contract_params, actual_contract_params);
}

#[test]
#[should_panic(expected: 'Amount is zero')]
fn test_swap_reverts_if_token_from_amount_is_zero() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();

    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
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
    start_cheat_caller_address_global(OPERATOR());
    autoswappr_dispatcher
        .avnu_swap(
            :token_from_address,
            :token_from_amount,
            :token_to_address,
            :token_to_amount,
            :token_to_min_amount,
            :beneficiary,
            :integrator_fee_amount_bps,
            :integrator_fee_recipient,
            :routes
        );
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Token not supported')]
fn test_swap_reverts_if_token_is_not_supported() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();

    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let token_from_address: ContractAddress = contract_address_const::<'RANDOM_TOKEN_ADDRESS'>();
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER());
    let token_to_address: ContractAddress = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    let token_to_amount: u256 = 5_000_000_000;
    let token_to_min_amount: u256 = 5_000_000_000;
    let beneficiary: ContractAddress = USER();
    let integrator_fee_amount_bps = 0;
    let integrator_fee_recipient: ContractAddress = contract_address_const::<0x0>();
    let mut routes: Array<Route> = ArrayTrait::new();
    start_cheat_caller_address_global(OPERATOR());
    autoswappr_dispatcher
        .avnu_swap(
            :token_from_address,
            :token_from_amount,
            :token_to_address,
            :token_to_amount,
            :token_to_min_amount,
            :beneficiary,
            :integrator_fee_amount_bps,
            :integrator_fee_recipient,
            :routes
        );
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_reverts_if_user_balance_is_lesser_than_swap_amount() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone()
    };
    let token_from_address: ContractAddress = strk_dispatcher.contract_address;
    let token_from_amount: u256 = strk_dispatcher.balance_of(USER()) * 2; // Double the balance

    // Don't approve tokens to trigger allowance check
    start_cheat_caller_address_global(OPERATOR());
    autoswappr_dispatcher
        .avnu_swap(
            token_from_address,
            token_from_amount,
            strk_dispatcher.contract_address,
            5_000_000_000,
            5_000_000_000,
            USER(),
            0,
            ZERO_ADDRESS(),
            ArrayTrait::new(),
        );
}

#[test]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_reverts_if_user_allowance_to_contract_is_lesser_than_swap_amount() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OPERATOR());
    let balance = strk_dispatcher.balance_of(USER());
    strk_dispatcher.approve(autoSwappr_contract_address, 0);

    autoswappr_dispatcher
        .avnu_swap(
            strk_dispatcher.contract_address,
            balance,
            eth_dispatcher.contract_address,
            5_000_000_000,
            5_000_000_000,
            USER(),
            0,
            ZERO_ADDRESS(),
            ArrayTrait::new(),
        );
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_set_operator_reverts_if_caller_is_not_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(USER());
    autoSwappr_dispatcher.set_operator(NEW_OPERATOR());
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'address already exist')]
fn test_set_operator_reverts_if_operator_already_exists() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());
    autoSwappr_dispatcher.set_operator(OPERATOR());
    stop_cheat_caller_address_global();
}

#[test]
fn test_set_operator_succeeds_when_called_by_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_operator(NEW_OPERATOR());
    stop_cheat_caller_address_global();

    // Assert that NEW_OPERATOR is now an operator
    assert(autoswappr_dispatcher.is_operator(NEW_OPERATOR()) == true, 'should be operator');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_remove_operator_reverts_if_caller_is_not_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(USER());
    autoSwappr_dispatcher.remove_operator(OPERATOR());
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'address does not exist')]
fn test_remove_operator_reverts_if_operator_does_not_exist() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());
    autoSwappr_dispatcher.remove_operator(NON_EXISTENT_OPERATOR());
    stop_cheat_caller_address_global();
}

#[test]
fn test_remove_operator_succeeds_when_called_by_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    // Remove the operator
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.remove_operator(OPERATOR());
    stop_cheat_caller_address_global();

    // Assert that OPERATOR is no longer an operator
    assert(autoswappr_dispatcher.is_operator(OPERATOR()) == false, 'should not be operator');
}

#[test]
fn test_set_operator_emits_event() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let mut spy = spy_events();
    let timestamp: u64 = 1000;

    start_cheat_block_timestamp(autoSwappr_contract_address, timestamp);
    start_cheat_caller_address_global(OWNER());
    autoSwappr_dispatcher.set_operator(NEW_OPERATOR());
    stop_cheat_caller_address_global();

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    Event::OperatorAdded(
                        OperatorAdded { operator: NEW_OPERATOR(), time_added: timestamp }
                    )
                )
            ]
        );
}

#[test]
fn test_remove_operator_emits_event() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let mut spy = spy_events();
    let timestamp: u64 = 1000;

    start_cheat_block_timestamp(autoSwappr_contract_address, timestamp);
    start_cheat_caller_address_global(OWNER());
    autoSwappr_dispatcher.remove_operator(OPERATOR());
    stop_cheat_caller_address_global();

    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_contract_address,
                    Event::OperatorRemoved(
                        OperatorRemoved { operator: OPERATOR(), time_removed: timestamp }
                    )
                )
            ]
        );
}


fn test_is_operator() {
    let (autoSwappr_contract_address, _, _) = __setup__();

    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());

    assert(autoSwappr_dispatcher.is_operator(USER()) == false, 'non operator');

    autoSwappr_dispatcher.set_operator(USER());

    assert(autoSwappr_dispatcher.is_operator(USER()) == true, 'is operator');
    stop_cheat_caller_address_global();
}

/////////////////////////////////////////////
// Test support_new_token_from,
// remove_token_from,
// get_token_from_status_and_value
/////////////////////////////////////////////

#[test]

fn test_get_token_from_status_and_value() {
    let (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let unsupported_token_address: ContractAddress = contract_address_const::<
        'UNSUPPORTED_TOKEN_ADDRESS'
    >();
    let (strk_status, strk_feed_id) = autoswappr_dispatcher
        .get_token_from_status_and_value(strk_dispatcher.contract_address);
    let (eth_status, eth_feed_id) = autoswappr_dispatcher
        .get_token_from_status_and_value(eth_dispatcher.contract_address);
    let (unsupported_token_status, unsupported_token_feed_id) = autoswappr_dispatcher
        .get_token_from_status_and_value(unsupported_token_address);

    assert(strk_status == true, 'strk token is not supported');
    assert(strk_feed_id == 'STRK/USD', 'strk token feed id is STRK/USD');

    assert(eth_status == true, 'eth token is not supported');
    assert(eth_feed_id == 'ETH/USD', 'eth token feed id is ETH/USD');

    assert(unsupported_token_status == false, 'unsupported token is supported');
    assert(unsupported_token_feed_id == '', 'unsupported token feed id is 0');
}

#[test]
#[should_panic(expected: 'Caller Not Owner')]
fn test_support_new_token_from_reverts_if_caller_is_not_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(USER());
    autoswappr_dispatcher
        .support_new_token_from(contract_address_const::<'USDC_TOKEN_ADDRESS'>(), 'USDC/USD');
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'Invalid function argument')]
fn test_support_new_token_from_reverts_if_feed_id_is_invalid() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher
        .support_new_token_from(contract_address_const::<'USDC_TOKEN_ADDRESS'>(), '');
    stop_cheat_caller_address_global();
}

#[test]
#[should_panic(expected: 'address already exist')]
fn test_support_new_token_from_reverts_if_token_is_already_supported() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.support_new_token_from(strk_dispatcher.contract_address, 'STRK/USD');
    stop_cheat_caller_address_global();
}

#[test]
fn test_support_new_token_from_with_valid_arguments() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let usdc_address = contract_address_const::<'USDC_TOKEN_ADDRESS'>();
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.support_new_token_from(usdc_address, 'USDC/USD');
    stop_cheat_caller_address_global();
    let (usdc_status, usdc_feed_id) = autoswappr_dispatcher
        .get_token_from_status_and_value(usdc_address);
    assert(usdc_status == true, 'usdc token is not supported');
    assert(usdc_feed_id == 'USDC/USD', 'usdc token feed id is USDC/USD');
}

//////////////////////////////////// remove_token_from ////////////
#[test]
#[should_panic(expected: 'Caller Not Owner')]
fn test_remove_token_from_reverts_if_caller_is_not_owner() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(USER());
    autoswappr_dispatcher.remove_token_from(strk_dispatcher.contract_address);
    stop_cheat_caller_address_global();
}


#[test]
#[should_panic(expected: 'Token not supported')]
fn test_remove_token_from_reverts_if_token_is_not_supported() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.remove_token_from(contract_address_const::<'USDC_TOKEN_ADDRESS'>());
    stop_cheat_caller_address_global();
}

#[test]
fn test_remove_token_from_with_valid_arguments() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.remove_token_from(strk_dispatcher.contract_address);
    stop_cheat_caller_address_global();
    let (strk_status, strk_feed_id) = autoswappr_dispatcher
        .get_token_from_status_and_value(strk_dispatcher.contract_address);

    assert(strk_status == false, 'strk should not be supported');
    assert(strk_feed_id == '', 'strk feed id should be empty');
}

//////////////////////////////////
// Test price feed integration
//////////////////////////////////

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_contract_fetches_eth_usd_price_correctly() {
    let (autoSwappr_contract_address, _, eth_dispatcher) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let eth_amount = 10; // 10 ether
    let usd_amount = autoswappr_dispatcher
        .get_token_amount_in_usd(eth_dispatcher.contract_address, eth_amount);
    println!("{} eth in usd using pragma oracle is {}", eth_amount, usd_amount);
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_tag: latest)]
fn test_contract_fetches_strk_usd_price_correctly() {
    let (autoSwappr_contract_address, strk_dispatcher, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };
    let strk_amount = 1000; // 1000 strk

    let usd_amount = autoswappr_dispatcher
        .get_token_amount_in_usd(strk_dispatcher.contract_address, strk_amount);
    println!("{} strk in usd using pragma oracle is {}", strk_amount, usd_amount);
}

#[test]
#[available_gas(2000000)]
fn test_set_fee_type_fixed_fee() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let mut spy = spy_events();

    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_fee_type(0, 500); // 0 for fixed fee, 500 basis points (5%)
    stop_cheat_caller_address_global();

    let contract_info = autoswappr_dispatcher.contract_parameters();
    assert(contract_info.fee_type == 0, 'Fee type should be fixed');
    assert(contract_info.percentage_fee == 500, 'Percentage fee should be 500');

    spy
    .assert_emitted(
        @array![
            (
                autoSwappr_contract_address,
                Event::FeeTypeChanged(FeeTypeChanged { new_fee_type: 0, new_percentage_fee: 500 })
            )
        ]
    );
}

#[test]
#[available_gas(2000000)]
fn test_set_fee_type_percentage_fee() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let mut spy = spy_events();

    start_cheat_caller_address_global(OWNER());
    autoswappr_dispatcher.set_fee_type(1, 200); // 1 for percentage fee, 200 basis points (2%)
    stop_cheat_caller_address_global();

    let contract_info = autoswappr_dispatcher.contract_parameters();
    assert(contract_info.fee_type == 1, 'Fee type should be percentage');
    assert(contract_info.percentage_fee == 200, 'Percentage fee should be 200');

    spy
    .assert_emitted(
        @array![
            (
                autoSwappr_contract_address,
                Event::FeeTypeChanged(FeeTypeChanged { new_fee_type: 1, new_percentage_fee: 200 })
            )
        ]
    );
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_fee_type_not_owner() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(USER());

    // This should panic
    autoswappr_dispatcher.set_fee_type(0, 500);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Invalid function argument',))]
fn test_set_fee_type_invalid_fee_type() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());

    // This should panic due to invalid fee type
    autoswappr_dispatcher.set_fee_type(2, 500);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Invalid function argument',))]
fn test_set_fee_type_invalid_percentage() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let autoswappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address
    };

    start_cheat_caller_address_global(OWNER());

    // This should panic due to invalid percentage (over 100%)
    autoswappr_dispatcher.set_fee_type(1, 10001);
}