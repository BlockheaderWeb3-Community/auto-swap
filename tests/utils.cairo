use starknet::{ContractAddress, contract_address_const};
use snforge_std::{start_cheat_account_contract_address, stop_cheat_account_contract_address};


use crate::constants::{
    STRK_TOKEN_ADDRESS, ETH_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, STRK_TOKEN,
    ETH_TOKEN, USDT_TOKEN, USDC_TOKEN, OPERATOR, FEE_COLLECTOR, EKUBO_CORE_ADDRESS, PoolKeyInternal,
    INITIAL_PERCENTAGE_FEE, INITIAL_FEE_TYPE, OWNER, ETH_USD_PRICE_FEED, STRK_USD_PRICE_FEED,
    PRICE_FEEDS_COUNT, SUPPORTED_ASSETS_COUNT, ORACLE_ADDRESS, FIBROUS_EXCHANGE_ADDRESS,
    AVNU_EXCHANGE_ADDRESS, FEE_AMOUNT_BPS, SwapType, WalletAmounts, JEDISWAP_POOL_ADDRESS,
    MIN_RECEIVED_STRK_TO_STABLE, MIN_RECEIVED_ETH_TO_STABLE, AMOUNT_TO_SWAP_ETH,
    AMOUNT_TO_SWAP_STRK, AVNUParams, SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, INTEGRATOR_FEE_AMOUNT,
    ROUTES_PERCENT, INTEGRATOR_FEE_RECIPIENT, EXCHANGE_ETH_USDC, EXCHANGE_ETH_USDT_EKUBO,
    EXCHANGE_ETH_USDT_SITH, EXCHANGE_STRK_USDT_POOL, EXCHANGE_STRK_USDC, EXCHANGE_STRK_USDT,
    ADDRESS_WITH_FUNDS
};

use crate::test_avnu_swap::{
    ADDRESS_WITH_FUNDS as ADDRESS_WITH_FUNDS_AVNU, AMOUNT_TO_SWAP_STRK as AMOUNT_TO_SWAP_STRK_AVNU,
    AMOUNT_TO_SWAP_ETH as AMOUNT_TO_SWAP_ETH_AVNU
};


use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};
use auto_swappr::base::types::{RouteParams, SwapParams, SwapData, Route};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


use ekubo::types::{i129::i129, keys::PoolKey};
use ekubo::interfaces::core::SwapParameters;
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait
};

//----UTILS----//
pub fn mag_into(amount: i129) -> u256 {
    amount.mag.into()
}

// util function for swap params
pub fn swap_param_util(swap_type: SwapType, amount: i129) -> SwapData {
    let pool_key = PoolKeyInternal {
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0,
        sqrt_ratio_limit: 18446748437148339061, // min sqrt ratio limit
    };
    let swap_params = SwapParameters {
        amount, sqrt_ratio_limit: pool_key.sqrt_ratio_limit, is_token1: false, skip_ahead: 0
    };

    match swap_type {
        SwapType::strk_usdc => {
            let pool_key = PoolKey {
                token0: STRK_TOKEN_ADDRESS(),
                token1: USDC_TOKEN_ADDRESS(),
                fee: pool_key.fee,
                tick_spacing: pool_key.tick_spacing,
                extension: pool_key.extension.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };

            swap_data
        },
        SwapType::strk_usdt => {
            // have to use another pool key for STRK/USDT as the default one has no trading volume
            let strk_usdt_pool_key = PoolKeyInternal {
                fee: 34028236692093847977029636859101184,
                tick_spacing: 354892,
                extension: 1919341413504682506464537888213340599793174343085035697059721110464975114204,
                sqrt_ratio_limit: 18446748437148339061, // min sqrt ratio limit
            };
            let pool_key = PoolKey {
                token0: STRK_TOKEN_ADDRESS(),
                token1: USDT_TOKEN_ADDRESS(),
                fee: strk_usdt_pool_key.fee,
                tick_spacing: strk_usdt_pool_key.tick_spacing,
                extension: strk_usdt_pool_key.extension.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };
            swap_data
        },
        SwapType::eth_usdt => {
            let pool_key = PoolKey {
                token0: ETH_TOKEN_ADDRESS(),
                token1: USDT_TOKEN_ADDRESS(),
                fee: pool_key.fee,
                tick_spacing: pool_key.tick_spacing,
                extension: pool_key.extension.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };
            swap_data
        },
        SwapType::eth_usdc => {
            let pool_key = PoolKey {
                token0: ETH_TOKEN_ADDRESS(),
                token1: USDC_TOKEN_ADDRESS(),
                fee: pool_key.fee,
                tick_spacing: pool_key.tick_spacing,
                extension: pool_key.extension.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };
            swap_data
        }
    }
}

// *************************************************************************
//                              SETUP
// *************************************************************************

pub fn __setup__() -> IAutoSwapprDispatcher {
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![];
    FEE_COLLECTOR.serialize(ref autoSwappr_constructor_calldata);
    FEE_AMOUNT_BPS.serialize(ref autoSwappr_constructor_calldata);
    AVNU_EXCHANGE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    FIBROUS_EXCHANGE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    EKUBO_CORE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    ORACLE_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    SUPPORTED_ASSETS_COUNT.serialize(ref autoSwappr_constructor_calldata);
    STRK_TOKEN_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    ETH_TOKEN_ADDRESS().serialize(ref autoSwappr_constructor_calldata);
    PRICE_FEEDS_COUNT.serialize(ref autoSwappr_constructor_calldata);
    STRK_USD_PRICE_FEED.serialize(ref autoSwappr_constructor_calldata);
    ETH_USD_PRICE_FEED.serialize(ref autoSwappr_constructor_calldata);
    OWNER().serialize(ref autoSwappr_constructor_calldata);
    INITIAL_FEE_TYPE.serialize(ref autoSwappr_constructor_calldata);
    INITIAL_PERCENTAGE_FEE.serialize(ref autoSwappr_constructor_calldata);

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: auto_swappr_contract_address,
    };

    let operator_dispatcher = IOperatorDispatcher {
        contract_address: auto_swappr_contract_address,
    };

    start_cheat_caller_address(auto_swappr_contract_address, OWNER().try_into().unwrap());
    operator_dispatcher.set_operator(OPERATOR());
    stop_cheat_caller_address(auto_swappr_contract_address);
    autoSwappr_dispatcher
}


////////// *************************************************************************
//                              FIBROUS SWAP UTILS
// *************************************************************************

pub fn call_fibrous_swap(
    autoSwappr_dispatcher: IAutoSwapprDispatcher,
    routeParams: RouteParams,
    swapParams: Array<SwapParams>,
    beneficiary: ContractAddress
) {
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, OPERATOR());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), OPERATOR());
    autoSwappr_dispatcher.fibrous_swap(routeParams, swapParams, beneficiary, beneficiary);
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());
}

// util function to fetch token balances (STRK, ETH, USDT, USDC) of a given account
pub fn get_wallet_amounts(wallet_address: ContractAddress) -> WalletAmounts {
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

pub fn approve_amount(
    token: ContractAddress, owner: ContractAddress, spender: ContractAddress, amount: u256
) {
    start_cheat_caller_address(token, owner);
    let token_dispatcher = IERC20Dispatcher { contract_address: token };
    token_dispatcher.approve(spender, amount);
    stop_cheat_caller_address(token);
}

pub fn get_swap_parameters(
    swap_type: SwapType, destination: ContractAddress
) -> (RouteParams, Array<SwapParams>) {
    let mut routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination
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
                    destination
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
                    destination
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
                    destination
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
                    destination
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


// *************************************************************************
//                     AVNU UTILS
// *************************************************************************
pub fn call_avnu_swap(
    autoSwappr_dispatcher: IAutoSwapprDispatcher,
    protocol_swapper: ContractAddress,
    token_from_address: ContractAddress,
    token_from_amount: u256,
    token_to_address: ContractAddress,
    token_to_min_amount: u256,
    beneficiary: ContractAddress,
    integrator_fee_amount_bps: u128,
    integrator_fee_recipient: ContractAddress,
    routes: Array<Route>,
) {
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, OPERATOR());
    autoSwappr_dispatcher
        .avnu_swap(
            protocol_swapper,
            token_from_address,
            token_from_amount,
            token_to_address,
            token_to_min_amount,
            beneficiary,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            routes,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
}

pub fn get_exchange_amount(
    token_dispatcher: IERC20Dispatcher, exchange_address: ContractAddress
) -> u256 {
    let amount = token_dispatcher.balance_of(exchange_address);
    amount
}

pub fn get_swap_parameters_avnu(swap_type: SwapType) -> AVNUParams {
    let mut params = AVNUParams {
        token_from_address: STRK_TOKEN_ADDRESS(),
        token_from_amount: AMOUNT_TO_SWAP_STRK_AVNU,
        token_to_address: USDT_TOKEN_ADDRESS(),
        token_to_min_amount: 510000
            - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
        beneficiary: ADDRESS_WITH_FUNDS_AVNU(),
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
                    token_from_amount: AMOUNT_TO_SWAP_STRK_AVNU,
                    token_to_address: USDT_TOKEN_ADDRESS(),
                    token_to_min_amount: 1020000
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS_AVNU(),
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
                    token_from_amount: AMOUNT_TO_SWAP_STRK_AVNU,
                    token_to_address: USDC_TOKEN_ADDRESS(),
                    token_to_min_amount: 465080 * 2
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS_AVNU(),
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
                    token_from_amount: AMOUNT_TO_SWAP_ETH_AVNU,
                    token_to_address: USDT_TOKEN_ADDRESS(),
                    token_to_min_amount: 659940
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS_AVNU(),
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
                    token_from_amount: AMOUNT_TO_SWAP_ETH_AVNU,
                    token_to_address: USDC_TOKEN_ADDRESS(),
                    token_to_min_amount: 659940
                        - SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN, // subtract a bit to give a margin
                    beneficiary: ADDRESS_WITH_FUNDS_AVNU(),
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

