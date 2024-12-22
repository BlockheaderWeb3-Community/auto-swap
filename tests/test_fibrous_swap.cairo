// *************************************************************************
//                              FIBROUS SWAP TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, start_cheat_account_contract_address, stop_cheat_account_contract_address,
};

use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{RouteParams, SwapParams};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

const OWNER: felt252 = 'OWNER';
const FEE_COLLECTOR: felt252 = 0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;

fn AVNU_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f>()
}
fn FIBROUS_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a>()
}

fn STRK_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

fn ETH_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
}

fn USDC_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x053C91253BC9682c04929cA02ED00b3E423f6710D2ee7e0D5EBB06F3eCF368A8>()
}

fn USDT_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x068F5c6a61780768455de69077E07e89787839bf8166dEcfBf92B645209c0fB8>()
}


fn ADDRESS_WITH_FUNDS() -> ContractAddress {
    // 0.01 ETH - 8.4 STRK
    contract_address_const::<0x049c6e318b49bfba4f38dd839e7a44010119c6188d1574e406dbbedef29d096d>()
}

fn JEDISWAP_POOL_ADDRESS() -> ContractAddress {
    contract_address_const::<0x5726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26>()
}

fn STRK_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() }
}

fn ETH_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() }
}

fn USDT_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() }
}

fn USDC_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() }
}

pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}

const AMOUNT_TO_SWAP_STRK: u256 = 1000000000000000000; // 1 STRK
const AMOUNT_TO_SWAP_ETH: u256 = 10000000000000000; // 0.01 ETH 
const MIN_RECEIVED_STRK_TO_STABLE: u256 = 550000; // 0.55 USD stable coin (USDC or USDT)
const MIN_RECEIVED_ETH_TO_STABLE: u256 = 38000000; // 38 USD stable coin (USDC or USDT) 

// UTILS
fn call_fibrous_swap(
    autoSwappr_dispatcher: IAutoSwapprDispatcher,
    routeParams: RouteParams,
    swapParams: Array<SwapParams>
) {
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_FUNDS());
    autoSwappr_dispatcher.fibrous_swap(routeParams, swapParams,);
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());
}

fn get_wallet_amounts(wallet_address: ContractAddress) -> WalletAmounts {
    start_cheat_caller_address(STRK_TOKEN().contract_address, wallet_address);
    start_cheat_caller_address(ETH_TOKEN().contract_address, wallet_address);
    start_cheat_caller_address(USDT_TOKEN().contract_address, wallet_address);
    start_cheat_caller_address(USDC_TOKEN().contract_address, wallet_address);
    let strk = STRK_TOKEN().balance_of(wallet_address);
    let eth = ETH_TOKEN().balance_of(wallet_address);
    let usdt = USDT_TOKEN().balance_of(wallet_address);
    let usdc = USDC_TOKEN().balance_of(wallet_address);
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    stop_cheat_caller_address(ETH_TOKEN().contract_address);
    stop_cheat_caller_address(USDT_TOKEN().contract_address);
    stop_cheat_caller_address(USDC_TOKEN().contract_address);

    let amounts = WalletAmounts { strk, eth, usdt, usdc };
    amounts
}

fn approve_amount(
    token: ContractAddress, owner: ContractAddress, spender: ContractAddress, amount: u256
) {
    start_cheat_caller_address(token, owner);
    let token_dispatcher = IERC20Dispatcher { contract_address: token };
    token_dispatcher.approve(spender, amount);
    stop_cheat_caller_address(token);
}

fn get_swap_parameters(swap_type: SwapType) -> (RouteParams, Array<SwapParams>) {
    let mut routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_FUNDS()
    };

    let swapParamsItem = SwapParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(),
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let mut swapParams = array![swapParamsItem];

    match swap_type {
        SwapType::strk_usdt => {
            routeParams =
                RouteParams {
                    token_in: STRK_TOKEN_ADDRESS(),
                    token_out: USDT_TOKEN_ADDRESS(),
                    amount_in: AMOUNT_TO_SWAP_STRK,
                    min_received: MIN_RECEIVED_STRK_TO_STABLE,
                    destination: ADDRESS_WITH_FUNDS()
                };

            let swapParamsItem = SwapParams {
                token_in: STRK_TOKEN_ADDRESS(),
                token_out: USDT_TOKEN_ADDRESS(),
                pool_address: JEDISWAP_POOL_ADDRESS(),
                rate: 1000000,
                protocol_id: 2,
                extra_data: array![],
            };
            swapParams = array![swapParamsItem];
        },
        SwapType::strk_usdc => {
            routeParams =
                RouteParams {
                    token_in: STRK_TOKEN_ADDRESS(),
                    token_out: USDC_TOKEN_ADDRESS(),
                    amount_in: AMOUNT_TO_SWAP_STRK,
                    min_received: MIN_RECEIVED_STRK_TO_STABLE,
                    destination: ADDRESS_WITH_FUNDS()
                };

            let swapParamsItem = SwapParams {
                token_in: STRK_TOKEN_ADDRESS(),
                token_out: USDC_TOKEN_ADDRESS(),
                pool_address: JEDISWAP_POOL_ADDRESS(),
                rate: 1000000,
                protocol_id: 2,
                extra_data: array![],
            };
            swapParams = array![swapParamsItem];
        },
        SwapType::eth_usdt => {
            routeParams =
                RouteParams {
                    token_in: ETH_TOKEN_ADDRESS(),
                    token_out: USDT_TOKEN_ADDRESS(),
                    amount_in: AMOUNT_TO_SWAP_ETH,
                    min_received: MIN_RECEIVED_ETH_TO_STABLE,
                    destination: ADDRESS_WITH_FUNDS()
                };

            let swapParamsItem = SwapParams {
                token_in: ETH_TOKEN_ADDRESS(),
                token_out: USDT_TOKEN_ADDRESS(),
                pool_address: JEDISWAP_POOL_ADDRESS(),
                rate: 1000000,
                protocol_id: 2,
                extra_data: array![],
            };
            swapParams = array![swapParamsItem];
        },
        SwapType::eth_usdc => {
            routeParams =
                RouteParams {
                    token_in: ETH_TOKEN_ADDRESS(),
                    token_out: USDC_TOKEN_ADDRESS(),
                    amount_in: AMOUNT_TO_SWAP_ETH,
                    min_received: MIN_RECEIVED_ETH_TO_STABLE,
                    destination: ADDRESS_WITH_FUNDS()
                };

            let swapParamsItem = SwapParams {
                token_in: ETH_TOKEN_ADDRESS(),
                token_out: USDC_TOKEN_ADDRESS(),
                pool_address: JEDISWAP_POOL_ADDRESS(),
                rate: 1000000,
                protocol_id: 2,
                extra_data: array![],
            };
            swapParams = array![swapParamsItem];
        },
    }
    (routeParams, swapParams)
}

#[derive(Drop, Serde, Clone, Debug)]
struct WalletAmounts {
    strk: u256,
    eth: u256,
    usdt: u256,
    usdc: u256,
}

#[derive(Drop, Serde, Clone, Debug)]
enum SwapType {
    strk_usdt,
    strk_usdc,
    eth_usdt,
    eth_usdc
}

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> IAutoSwapprDispatcher {
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut auto_swappr_constructor_calldata: Array<felt252> = array![
        FEE_COLLECTOR,
        AVNU_EXCHANGE_ADDRESS().into(),
        FIBROUS_EXCHANGE_ADDRESS().into(),
        ORACLE_ADDRESS().into(),
        STRK_TOKEN_ADDRESS().into(),
        ETH_TOKEN_ADDRESS().into(),
        OWNER,
    ];

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@auto_swappr_constructor_calldata)
        .unwrap();

    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: auto_swappr_contract_address,
    };
    autoSwappr_dispatcher
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdt() {
    let autoSwappr_dispatcher = __setup__();
    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let (routeParams, swapParams) = get_swap_parameters(SwapType::strk_usdt);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);

    // asserts
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_STRK_TO_STABLE,
        "Balance of to token should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let (routeParams, swapParams) = get_swap_parameters(SwapType::strk_usdc);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);

    // asserts
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_STRK_TO_STABLE,
        "Balance of to token should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
fn test_fibrous_swap_eth_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams, swapParams) = get_swap_parameters(SwapType::eth_usdt);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);

    // asserts
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_ETH_TO_STABLE,
        "Balance of to token should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
fn test_fibrous_swap_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams, swapParams) = get_swap_parameters(SwapType::eth_usdc);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);

    // asserts
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_ETH_TO_STABLE,
        "Balance of to token should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
fn test_fibrous_swap_strk_to_usdt_and_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let (routeParams_strk_to_usdt, swapParams_strk_to_usdt) = get_swap_parameters(
        SwapType::strk_usdt
    );
    let (routeParams_eth_to_usdc, swapParams_eth_to_usdc) = get_swap_parameters(SwapType::eth_usdc);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams_strk_to_usdt, swapParams_strk_to_usdt);
    call_fibrous_swap(autoSwappr_dispatcher, routeParams_eth_to_usdc, swapParams_eth_to_usdc);

    // asserts
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_FUNDS());
    assert_eq!(
        STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "STRK Balance of from token should decrease"
    );
    assert_ge!(
        USDT_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdt + MIN_RECEIVED_STRK_TO_STABLE,
        "USDT Balance of to token should increase"
    );
    assert_eq!(
        ETH_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "ETH Balance of from token should decrease"
    );
    assert_ge!(
        USDC_TOKEN().balance_of(ADDRESS_WITH_FUNDS()),
        previous_amounts.usdc + MIN_RECEIVED_ETH_TO_STABLE,
        "USDC Balance of to token should increase"
    );
}


#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_fibrous_swap_should_fail_for_insufficient_allowance_to_contract() {
    let autoSwappr_dispatcher = __setup__();

    // not allow so the error will occurs
    // approve_amount(STRK_TOKEN().contract_address, ADDRESS_WITH_FUNDS(),
    // autoSwappr_dispatcher.contract_address,  AMOUNT_TO_SWAP_STRK);

    let (routeParams, swapParams) = get_swap_parameters(SwapType::strk_usdt);

    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 993231)]
#[should_panic(expected: 'Token not supported')]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    let autoSwappr_dispatcher = __setup__();

    let unsupported_token = contract_address_const::<0x123>();

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let routeParams = RouteParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_FUNDS()
    };

    let swapParamsItem = SwapParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(),
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];

    // Calling function
    call_fibrous_swap(autoSwappr_dispatcher, routeParams, swapParams);
}

