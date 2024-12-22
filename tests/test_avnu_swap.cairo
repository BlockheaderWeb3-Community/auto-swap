// *************************************************************************
//                              AVNU SWAP TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, start_cheat_account_contract_address, stop_cheat_account_contract_address,
    spy_events, EventSpyAssertionsTrait
};

use auto_swappr::autoswappr::AutoSwappr::{Event, SwapSuccessful};
use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::Route;
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
    contract_address_const::<0x298a9d0d82aabfd7e2463bb5ec3590c4e86d03b2ece868d06bbe43475f2d3e6>()
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

fn INTEGRATOR_FEE_RECIPIENT() -> ContractAddress {
    contract_address_const::<0>()
}

fn EXCHANGE_STRK_USDT() -> ContractAddress {
    contract_address_const::<
        0x359550b990167afd6635fa574f3bdadd83cb51850e1d00061fe693158c23f80
    >() // jedi swap: swap router v2
}
fn EXCHANGE_STRK_USDT_POOL() -> ContractAddress {
    // Sometimes the exchange contract takes the currencies to swap from another contract, in this
    // case, the first address of the route extra params
    contract_address_const::<
        0xb74193526135104973a1e285bb0372adf41a5d7a8fc5e6f30ea535847613ce
    >() // jedi swap: swap router v2
}

fn EXCHANGE_STRK_USDC() -> ContractAddress {
    contract_address_const::<
        0x41fd22b238fa21cfcf5dd45a8548974d8263b3a531a60388411c5e230f97023
    >() // jedi swap: AMM swap
}

fn EXCHANGE_STRK_USDC_POOL() -> ContractAddress {
    contract_address_const::<
        0x05726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26
    >() // jedi swap: AMM swap
}

fn EXCHANGE_ETH_USDT_POOL() -> ContractAddress {
    contract_address_const::<0x0351d125294ae90c5ac53405ebc491d5d910e4f903cdc5d8c0d342dfa71fd0e9>()
}

fn EXCHANGE_ETH_USDT_SITH() -> ContractAddress {
    contract_address_const::<
        0x28c858a586fa12123a1ccb337a0a3b369281f91ea00544d0c086524b759f627
    >() // sith swap: AMM router
}

fn EXCHANGE_ETH_USDT_EKUBO() -> ContractAddress {
    contract_address_const::<
        158098919692956613592021320609952044916245725306097615271255138786123
    >() // EKUBO core
}

fn EXCHANGE_ETH_USDC() -> ContractAddress {
    contract_address_const::<
        0x1114c7103e12c2b2ecbd3a2472ba9c48ddcbf702b1c242dd570057e26212111
    >() // myswap: CL AMM swap
}

pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}


const AMOUNT_TO_SWAP_STRK: u256 = 1000000000000000000; // 1 STRK
const AMOUNT_TO_SWAP_ETH: u256 = 200000000000000; // 0.0002 ETH 

const SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN: u256 = 1000;
const ROUTES_PERCENT: u128 = 1000000000000;
const INTEGRATOR_FEE_AMOUNT: u128 = 0;


// *************************************************************************
//                      UTILS
// *************************************************************************
fn call_avnu_swap(
    autoSwappr_dispatcher: IAutoSwapprDispatcher,
    token_from_address: ContractAddress,
    token_from_amount: u256,
    token_to_address: ContractAddress,
    token_to_amount: u256,
    token_to_min_amount: u256,
    beneficiary: ContractAddress,
    integrator_fee_amount_bps: u128,
    integrator_fee_recipient: ContractAddress,
    routes: Array<Route>,
) {
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_FUNDS());
    start_cheat_account_contract_address(AVNU_EXCHANGE_ADDRESS(), ADDRESS_WITH_FUNDS());
    autoSwappr_dispatcher
        .avnu_swap(
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
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(AVNU_EXCHANGE_ADDRESS());
}

// util function to fetch token balances (STRK, ETH, USDT, USDC) of a given account
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

fn get_exchange_amount(
    token_dispatcher: IERC20Dispatcher, exchange_address: ContractAddress
) -> u256 {
    let amount = token_dispatcher.balance_of(exchange_address);
    amount
}

fn approve_amount(
    token: ContractAddress, owner: ContractAddress, spender: ContractAddress, amount: u256
) {
    start_cheat_caller_address(token, owner);
    let token_dispatcher = IERC20Dispatcher { contract_address: token };
    token_dispatcher.approve(spender, amount);
    stop_cheat_caller_address(token);
}

fn get_swap_parameters(swap_type: SwapType) -> AVNUParams {
    let mut params = AVNUParams {
        token_from_address: STRK_TOKEN_ADDRESS(),
        token_from_amount: AMOUNT_TO_SWAP_STRK,
        token_to_address: USDT_TOKEN_ADDRESS(),
        token_to_amount: 510000,
        token_to_min_amount: 510000
            - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
        beneficiary: ADDRESS_WITH_FUNDS(),
        integrator_fee_amount_bps: INTEGRATOR_FEE_AMOUNT,
        integrator_fee_recipient: INTEGRATOR_FEE_RECIPIENT(),
        routes: array![
            Route {
                token_from: STRK_TOKEN_ADDRESS(),
                token_to: USDT_TOKEN_ADDRESS(),
                exchange_address: EXCHANGE_STRK_USDT(),
                percent: ROUTES_PERCENT,
                additional_swap_params: array![
                    EXCHANGE_STRK_USDT_POOL().into(), 1018588075927140995502, 3000
                ],
            }
        ]
    };

    match swap_type {
        // test based on this tx ->
        // https://starkscan.co/tx/0x014ed3ebca0d2f1bc33b025da8fb4547f1d45e1b7d1681262e6756bbd698b03a
        SwapType::strk_usdt => {
            params =
                AVNUParams {
                    token_from_address: STRK_TOKEN_ADDRESS(),
                    token_from_amount: AMOUNT_TO_SWAP_STRK,
                    token_to_address: USDT_TOKEN_ADDRESS(),
                    token_to_amount: 510000,
                    token_to_min_amount: 510000
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS(),
                    integrator_fee_amount_bps: INTEGRATOR_FEE_AMOUNT,
                    integrator_fee_recipient: INTEGRATOR_FEE_RECIPIENT(),
                    routes: array![
                        Route {
                            token_from: STRK_TOKEN_ADDRESS(),
                            token_to: USDT_TOKEN_ADDRESS(),
                            exchange_address: EXCHANGE_STRK_USDT(),
                            percent: ROUTES_PERCENT,
                            additional_swap_params: array![
                                EXCHANGE_STRK_USDT_POOL().into(), 1018588075927140995502, 3000
                            ],
                        }
                    ]
                };
        },
        // based on tx
        // https://starkscan.co/tx/0x507b8d0d38e604ecdb87f06254e8d07a2569363520bf15d3d03e5743c299cd3
        SwapType::strk_usdc => {
            params =
                AVNUParams {
                    token_from_address: STRK_TOKEN_ADDRESS(),
                    token_from_amount: AMOUNT_TO_SWAP_STRK,
                    token_to_address: USDC_TOKEN_ADDRESS(),
                    token_to_amount: 465080,
                    token_to_min_amount: 465080
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS(),
                    integrator_fee_amount_bps: INTEGRATOR_FEE_AMOUNT,
                    integrator_fee_recipient: INTEGRATOR_FEE_RECIPIENT(),
                    routes: array![
                        Route {
                            token_from: STRK_TOKEN_ADDRESS(),
                            token_to: USDC_TOKEN_ADDRESS(),
                            exchange_address: EXCHANGE_STRK_USDC(),
                            percent: ROUTES_PERCENT,
                            additional_swap_params: array![],
                        }
                    ]
                };
        },
        // based on tx
        // https://starkscan.co/tx/0x15df9c1387c59bb7ba0f82703d448e522a1a392ee0d968227b6882f16e80e1f
        SwapType::eth_usdt => {
            params =
                AVNUParams {
                    token_from_address: ETH_TOKEN_ADDRESS(),
                    token_from_amount: AMOUNT_TO_SWAP_ETH,
                    token_to_address: USDT_TOKEN_ADDRESS(),
                    token_to_amount: 659940,
                    token_to_min_amount: 659940
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS(),
                    integrator_fee_amount_bps: INTEGRATOR_FEE_AMOUNT,
                    integrator_fee_recipient: INTEGRATOR_FEE_RECIPIENT(),
                    routes: array![
                        Route {
                            token_from: ETH_TOKEN_ADDRESS(), // ETH
                            token_to: contract_address_const::<
                                0x124aeb495b947201f5fac96fd1138e326ad86195b98df6dec9009158a533b49
                            >(), // Realms: LORDS
                            exchange_address: EXCHANGE_ETH_USDT_EKUBO(),
                            percent: ROUTES_PERCENT,
                            additional_swap_params: array![
                                0x124aeb495b947201f5fac96fd1138e326ad86195b98df6dec9009158a533b49,
                                0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7,
                                3402823669209384634633746074317682114,
                                'MZ',
                                0,
                                3519403778994931520712610040380
                            ],
                        },
                        Route {
                            token_from: contract_address_const::<
                                0x124aeb495b947201f5fac96fd1138e326ad86195b98df6dec9009158a533b49
                            >(), // Realms: LORDS
                            token_to: USDT_TOKEN_ADDRESS(),
                            exchange_address: EXCHANGE_ETH_USDT_SITH(),
                            percent: ROUTES_PERCENT,
                            additional_swap_params: array![0],
                        }
                    ]
                };
        },
        // based on tx
        // https://starkscan.co/tx/0x5be8a02e5c4c41fea081f7f4977439f7029168f6ff1d165949dcbf8be55c200
        SwapType::eth_usdc => {
            params =
                AVNUParams {
                    token_from_address: ETH_TOKEN_ADDRESS(),
                    token_from_amount: AMOUNT_TO_SWAP_ETH,
                    token_to_address: USDC_TOKEN_ADDRESS(),
                    token_to_amount: 659940,
                    token_to_min_amount: 659940
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS(),
                    integrator_fee_amount_bps: INTEGRATOR_FEE_AMOUNT,
                    integrator_fee_recipient: INTEGRATOR_FEE_RECIPIENT(),
                    routes: array![
                        Route {
                            token_from: contract_address_const::<
                                0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                            >(), // ETH
                            token_to: contract_address_const::<
                                0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8
                            >(), // USDC
                            exchange_address: EXCHANGE_ETH_USDC(),
                            percent: ROUTES_PERCENT,
                            additional_swap_params: array![
                                0x71273c5c5780b4be42d9e6567b1b1a6934f43ab8abaf975c0c3da219fc4d040,
                                4305411938843418615
                            ],
                        },
                    ]
                };
        },
    };

    params
}


#[derive(Drop, Serde, Debug)]
struct AVNUParams {
    token_from_address: ContractAddress,
    token_from_amount: u256,
    token_to_address: ContractAddress,
    token_to_amount: u256,
    token_to_min_amount: u256,
    beneficiary: ContractAddress,
    integrator_fee_amount_bps: u128,
    integrator_fee_recipient: ContractAddress,
    routes: Array<Route>,
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

    start_cheat_caller_address(auto_swappr_contract_address, OWNER.try_into().unwrap());
    autoSwappr_dispatcher.set_operator(ADDRESS_WITH_FUNDS());
    stop_cheat_caller_address(auto_swappr_contract_address);

    autoSwappr_dispatcher
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
fn test_avnu_swap_strk_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_exchange_amount_strk = get_exchange_amount(
        STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );
    let previous_exchange_amount_usdt = get_exchange_amount(
        USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL()
    );

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_strk = get_exchange_amount(STRK_TOKEN(), EXCHANGE_STRK_USDT_POOL());
    let new_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_STRK_USDT_POOL());

    // assertions
    assert_eq!(
        new_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );

    assert_eq!(new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged");

    assert_ge!(
        new_amounts.usdt,
        previous_amounts.usdt
            + (params.token_to_min_amount - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN),
        "Balance of to token should increase"
    );

    // assertions for the exchange
    assert_le!(
        new_exchange_amount_usdt,
        previous_exchange_amount_usdt - params.token_to_min_amount,
        "Exchange address USDT balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_strk,
        previous_exchange_amount_strk + AMOUNT_TO_SWAP_STRK,
        "Exchange address STRK balance should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996957)]
fn test_avnu_swap_strk_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_exchange_amount_strk = get_exchange_amount(
        STRK_TOKEN(), EXCHANGE_STRK_USDC_POOL()
    );
    let previous_exchange_amount_usdc = get_exchange_amount(
        USDC_TOKEN(), EXCHANGE_STRK_USDC_POOL()
    );

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_strk = get_exchange_amount(STRK_TOKEN(), EXCHANGE_STRK_USDC_POOL());
    let new_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_STRK_USDC_POOL());

    // assertions
    assert_eq!(
        new_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdc,
        previous_amounts.usdc
            + (params.token_to_min_amount - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN),
        "Balance of to token should increase"
    );

    // assertions for the exchange
    assert_le!(
        new_exchange_amount_usdc,
        previous_exchange_amount_usdc - params.token_to_min_amount,
        "Exchange address USDC balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_strk,
        previous_exchange_amount_strk + AMOUNT_TO_SWAP_STRK,
        "Exchange address STRK balance should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 997043)]
fn test_avnu_swap_eth_to_usdt() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDT_EKUBO());
    let previous_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_ETH_USDT_POOL());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    let new_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDT_EKUBO());
    let new_exchange_amount_usdt = get_exchange_amount(USDT_TOKEN(), EXCHANGE_ETH_USDT_POOL());

    // assertion
    assert_eq!(
        new_amounts.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdt,
        previous_amounts.usdt
            + (params.token_to_min_amount - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN),
        "Balance of to token should increase"
    );

    // avnu post-swap assertions
    assert_le!(
        new_exchange_amount_usdt,
        // previous_exchange_amount_usdt - params.token_to_min_amount + 1000, // for this special
        // case, AVNU is taking a % of the USDT to send from his own balance and not from the called
        // pool, so we add that aprox. remainder here
        previous_exchange_amount_usdt - params.token_to_min_amount,
        "Exchange address USDT balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_eth,
        previous_exchange_amount_eth + AMOUNT_TO_SWAP_ETH,
        "Exchange address ETH balance should increase"
    );
}

#[test]
// #[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 997080)]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 1002124)]
fn test_avnu_swap_eth_to_usdc() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let previous_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDC());
    let previous_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_ETH_USDC());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    let new_exchange_amount_eth = get_exchange_amount(ETH_TOKEN(), EXCHANGE_ETH_USDC());
    let new_exchange_amount_usdc = get_exchange_amount(USDC_TOKEN(), EXCHANGE_ETH_USDC());

    // assertion
    assert_eq!(
        new_amounts.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "Balance of from token should decrease"
    );

    assert_ge!(
        new_amounts.usdc,
        previous_amounts.usdc
            + (params.token_to_min_amount - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN),
        "Balance of to token should increase"
    );

    // avnu post-swap assertions
    assert_le!(
        new_exchange_amount_usdc,
        previous_exchange_amount_usdc - params.token_to_min_amount,
        "Exchange address USDC balance should decrease"
    );

    assert_eq!(
        new_exchange_amount_eth,
        previous_exchange_amount_eth + AMOUNT_TO_SWAP_ETH,
        "Exchange address ETH balance should increase"
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 999126)]
fn test_multi_swaps() {
    let autoSwappr_dispatcher = __setup__();

    // params
    let params_strk_to_usdt = get_swap_parameters(SwapType::strk_usdt);
    let params_strk_to_usdc = get_swap_parameters(SwapType::strk_usdc);
    let params_eth_to_usdt = get_swap_parameters(SwapType::eth_usdt);
    let params_eth_to_usdc = get_swap_parameters(SwapType::eth_usdc);

    // In the block used for the test, the value of the STRK token is less than the on returned from
    // get_swap_parameters so we replace it with the next value (this is an specific case for this
    // test, so it's better to handle it locally)
    let strk_to_stable_min_amount = 420000;
    let eth_to_stable_min_amount = 595791;

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    //strk to usdt
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_strk_to_usdt.token_from_address,
        params_strk_to_usdt.token_from_amount,
        params_strk_to_usdt.token_to_address,
        params_strk_to_usdt.token_to_amount,
        // params_strk_to_usdt.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdt.beneficiary,
        params_strk_to_usdt.integrator_fee_amount_bps,
        params_strk_to_usdt.integrator_fee_recipient,
        params_strk_to_usdt.routes
    );
    let amounts_after_strk_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_strk_to_usdt.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "(amounts_after_strk_to_usdt) STRK Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_strk_to_usdt.usdt,
        previous_amounts.usdt + strk_to_stable_min_amount,
        "(amounts_after_strk_to_usdt) USDT Balance of to token should increase"
    );
    // // strk to usdc
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_strk_to_usdc.token_from_address,
        params_strk_to_usdc.token_from_amount,
        params_strk_to_usdc.token_to_address,
        params_strk_to_usdc.token_to_amount,
        // params_strk_to_usdc.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdc.beneficiary,
        params_strk_to_usdc.integrator_fee_amount_bps,
        params_strk_to_usdc.integrator_fee_recipient,
        params_strk_to_usdc.routes
    );
    let amounts_after_strk_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_strk_to_usdc.strk,
        amounts_after_strk_to_usdt.strk - AMOUNT_TO_SWAP_STRK,
        "(amounts_after_strk_to_usdc) STRK Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_strk_to_usdc.usdc,
        amounts_after_strk_to_usdt.usdc + strk_to_stable_min_amount,
        "(amounts_after_strk_to_usdc) USDC Balance of to token should increase"
    );
    // eth to usdt
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_eth_to_usdt.token_from_address,
        params_eth_to_usdt.token_from_amount,
        params_eth_to_usdt.token_to_address,
        params_eth_to_usdt.token_to_amount,
        // params_eth_to_usdt.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdt.beneficiary,
        params_eth_to_usdt.integrator_fee_amount_bps,
        params_eth_to_usdt.integrator_fee_recipient,
        params_eth_to_usdt.routes
    );
    let amounts_after_eth_to_usdt = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_eth_to_usdt.eth,
        previous_amounts.eth - AMOUNT_TO_SWAP_ETH,
        "(amounts_after_eth_to_usdt) ETH Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_eth_to_usdt.usdt,
        amounts_after_strk_to_usdc.usdt + eth_to_stable_min_amount,
        "(amounts_after_eth_to_usdt) USDT Balance of to token should increase"
    );
    // eth to usdc
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_eth_to_usdc.token_from_address,
        params_eth_to_usdc.token_from_amount,
        params_eth_to_usdc.token_to_address,
        params_eth_to_usdc.token_to_amount,
        // params_eth_to_usdc.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdc.beneficiary,
        params_eth_to_usdc.integrator_fee_amount_bps,
        params_eth_to_usdc.integrator_fee_recipient,
        params_eth_to_usdc.routes
    );
    let amounts_after_eth_to_usdc = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        amounts_after_eth_to_usdc.eth,
        amounts_after_eth_to_usdt.eth - AMOUNT_TO_SWAP_ETH,
        "(amounts_after_eth_to_usdc) ETH Balance of from token should decrease"
    );
    assert_ge!(
        amounts_after_eth_to_usdc.usdc,
        amounts_after_eth_to_usdt.usdc + eth_to_stable_min_amount,
        "(amounts_after_eth_to_usdc) USDC Balance of to token should increase"
    );

    let final_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    assert_eq!(
        final_amounts.strk,
        previous_amounts.strk
            - AMOUNT_TO_SWAP_STRK
                * 2, // times 2 because we swap to stable twice one from STRK and one from ETH
        "STRK Balance of from token should decrease"
    );
    assert_eq!(
        final_amounts.eth,
        previous_amounts.eth
            - AMOUNT_TO_SWAP_ETH
                * 2, // times 2 because we swap to stable twice one from STRK and one from ETH
        "ETH Balance of from token should decrease"
    );

    assert_ge!(
        final_amounts.usdt,
        previous_amounts.usdt
            + (strk_to_stable_min_amount
                + eth_to_stable_min_amount), // should increase the sum of strk and eth swaps to usdt
        "USDT Balance of to token should increase"
    );

    assert_ge!(
        final_amounts.usdc,
        previous_amounts.usdc
            + (eth_to_stable_min_amount
                + strk_to_stable_min_amount), // should increase the sum of strk and eth swaps to usdc
        "USDC Balance of to token should increase"
    );
}

// *************************************************************************
//                        UNCHANGED TOKEN BALANCES AFTER SWAPS
// *************************************************************************
#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
fn test_unswapped_token_balances_should_remain_unchanged_for_strk_usdt_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.eth, previous_amounts.eth, "ETH balance should remain unchanged"
    ); // unchanged ETH token balance
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996957)]
fn test_unswapped_token_balances_should_remain_unchanged_for_strk_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdt, previous_amounts.usdt, "USDT balance should remain unchanged"
    ); // unchanged USDT token balance
    assert_eq!(
        new_amounts.eth, previous_amounts.eth, "ETH balance should remain unchanged"
    ); // unchanged ETH token balance
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 997043)]
fn test_unswapped_token_balances_should_remain_unchanged_for_eth_usdt_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdc, previous_amounts.usdc, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.strk, previous_amounts.strk, "STRK balance should remain unchanged"
    ); // unchanged STRK token balance
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 997043)]
fn test_unswapped_token_balances_should_remain_unchanged_for_eth_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();

    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );

    let params = get_swap_parameters(SwapType::eth_usdc);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount
            - 10000, // original:679940 -> give a bit more margin cause test was failing due to 'Insufficient tokens received'
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
    let new_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    // assertions
    assert_eq!(
        new_amounts.usdt, previous_amounts.usdt, "USDC balance should remain unchanged"
    ); // unchanged USDC token balance
    assert_eq!(
        new_amounts.strk, previous_amounts.strk, "STRK balance should remain unchanged"
    ); // unchanged STRK token balance
}

// *************************************************************************
//                        EVENT EMISSIONS
// *************************************************************************
#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
fn test_avnu_swap_event_emission() {
    let mut spy = spy_events();
    let autoSwappr_dispatcher = __setup__();

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );

    // events assertion
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params.token_from_address,
                            token_from_amount: params.token_from_amount,
                            token_to_address: params.token_to_address,
                            token_to_amount: params.token_to_amount,
                            beneficiary: params.beneficiary,
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 999126)]
fn test_multi_swaps_event_emission() {
    let mut spy = spy_events();
    let autoSwappr_dispatcher = __setup__();

    // params
    let params_strk_to_usdt = get_swap_parameters(SwapType::strk_usdt);
    let params_strk_to_usdc = get_swap_parameters(SwapType::strk_usdc);
    let params_eth_to_usdt = get_swap_parameters(SwapType::eth_usdt);
    let params_eth_to_usdc = get_swap_parameters(SwapType::eth_usdc);

    let strk_to_stable_min_amount = 420000;
    let eth_to_stable_min_amount = 595791;

    // strk to usdt
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_strk_to_usdt.token_from_address,
        params_strk_to_usdt.token_from_amount,
        params_strk_to_usdt.token_to_address,
        params_strk_to_usdt.token_to_amount,
        // params_strk_to_usdt.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdt.beneficiary,
        params_strk_to_usdt.integrator_fee_amount_bps,
        params_strk_to_usdt.integrator_fee_recipient,
        params_strk_to_usdt.routes
    );

    // strk to usdc
    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_strk_to_usdc.token_from_address,
        params_strk_to_usdc.token_from_amount,
        params_strk_to_usdc.token_to_address,
        params_strk_to_usdc.token_to_amount,
        // params_strk_to_usdc.token_to_min_amount,
        strk_to_stable_min_amount,
        params_strk_to_usdc.beneficiary,
        params_strk_to_usdc.integrator_fee_amount_bps,
        params_strk_to_usdc.integrator_fee_recipient,
        params_strk_to_usdc.routes
    );

    // eth to usdt
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_eth_to_usdt.token_from_address,
        params_eth_to_usdt.token_from_amount,
        params_eth_to_usdt.token_to_address,
        params_eth_to_usdt.token_to_amount,
        // params_eth_to_usdt.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdt.beneficiary,
        params_eth_to_usdt.integrator_fee_amount_bps,
        params_eth_to_usdt.integrator_fee_recipient,
        params_eth_to_usdt.routes
    );

    // eth to usdc
    approve_amount(
        ETH_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_ETH
    );
    call_avnu_swap(
        autoSwappr_dispatcher,
        params_eth_to_usdc.token_from_address,
        params_eth_to_usdc.token_from_amount,
        params_eth_to_usdc.token_to_address,
        params_eth_to_usdc.token_to_amount,
        // params_eth_to_usdc.token_to_min_amount,
        eth_to_stable_min_amount,
        params_eth_to_usdc.beneficiary,
        params_eth_to_usdc.integrator_fee_amount_bps,
        params_eth_to_usdc.integrator_fee_recipient,
        params_eth_to_usdc.routes
    );

    // events assertions
    spy
        .assert_emitted(
            @array![
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_strk_to_usdt.token_from_address,
                            token_from_amount: params_strk_to_usdt.token_from_amount,
                            token_to_address: params_strk_to_usdt.token_to_address,
                            token_to_amount: params_strk_to_usdt.token_to_amount,
                            beneficiary: params_strk_to_usdt.beneficiary,
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_strk_to_usdc.token_from_address,
                            token_from_amount: params_strk_to_usdc.token_from_amount,
                            token_to_address: params_strk_to_usdc.token_to_address,
                            token_to_amount: params_strk_to_usdc.token_to_amount,
                            beneficiary: params_strk_to_usdc.beneficiary,
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_eth_to_usdt.token_from_address,
                            token_from_amount: params_eth_to_usdt.token_from_amount,
                            token_to_address: params_eth_to_usdt.token_to_address,
                            token_to_amount: params_eth_to_usdt.token_to_amount,
                            beneficiary: params_eth_to_usdt.beneficiary,
                        }
                    )
                ),
                (
                    autoSwappr_dispatcher.contract_address,
                    Event::SwapSuccessful(
                        SwapSuccessful {
                            token_from_address: params_eth_to_usdc.token_from_address,
                            token_from_amount: params_eth_to_usdc.token_from_amount,
                            token_to_address: params_eth_to_usdc.token_to_address,
                            token_to_amount: params_eth_to_usdc.token_to_amount,
                            beneficiary: params_eth_to_usdc.beneficiary,
                        }
                    )
                )
            ]
        );
}

// *************************************************************************
//                        SHOULD PANIC CASES
// *************************************************************************
#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_avnu_swap_should_fail_for_insufficient_allowance_to_contract() {
    let autoSwappr_dispatcher = __setup__();

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params.token_from_address,
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
#[should_panic(expected: 'Token not supported')]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    let autoSwappr_dispatcher = __setup__();

    let params = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        // params.token_from_address,
        contract_address_const::<0x123>(), // unsupported token
        params.token_from_amount,
        params.token_to_address,
        params.token_to_amount,
        params.token_to_min_amount,
        params.beneficiary,
        params.integrator_fee_amount_bps,
        params.integrator_fee_recipient,
        params.routes
    );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 996491)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_swap_should_fail_after_token_approval_is_revoked_avnu() {
    let autoSwappr_dispatcher = __setup__();
    let previous_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        AMOUNT_TO_SWAP_STRK
    );

    let params1 = get_swap_parameters(SwapType::strk_usdt);
    
    call_avnu_swap(
        autoSwappr_dispatcher,
        params1.token_from_address,
        params1.token_from_amount,
        params1.token_to_address,
        params1.token_to_amount,
        params1.token_to_min_amount,
        params1.beneficiary,
        params1.integrator_fee_amount_bps,
        params1.integrator_fee_recipient,
        params1.routes
    );

    let post_swap_amounts = get_wallet_amounts(ADDRESS_WITH_FUNDS());
    assert_eq!(
        post_swap_amounts.strk,
        previous_amounts.strk - AMOUNT_TO_SWAP_STRK,
        "First swap should decrease STRK balance"
    );

    approve_amount(
        STRK_TOKEN().contract_address,
        ADDRESS_WITH_FUNDS(),
        autoSwappr_dispatcher.contract_address,
        0
    );

    let params2 = get_swap_parameters(SwapType::strk_usdt);

    call_avnu_swap(
        autoSwappr_dispatcher,
        params2.token_from_address,
        params2.token_from_amount,
        params2.token_to_address,
        params2.token_to_amount,
        params2.token_to_min_amount,
        params2.beneficiary,
        params2.integrator_fee_amount_bps,
        params2.integrator_fee_recipient,
        params2.routes
    );
}



