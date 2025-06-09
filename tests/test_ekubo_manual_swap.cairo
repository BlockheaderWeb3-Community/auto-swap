// *************************************************************************
//                              EKUBO SWAP TEST
// *************************************************************************
// starknet imports
use starknet::{ContractAddress, contract_address_const};

// snforge imports
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, cheat_caller_address, CheatSpan, spy_events, EventSpyAssertionsTrait
};

// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Autoswappr imports
use auto_swappr::autoswappr::AutoSwappr::{Event, SwapSuccessful};
use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{FeeType, SwapData};
use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};

// Ekubo imports
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use ekubo::interfaces::core::SwapParameters;
use ekubo::interfaces::core::{ILockerDispatcher, ILockerDispatcherTrait};


const FEE_COLLECTOR: felt252 = 0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;

fn AVNU_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f>()
}

fn FIBROUS_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a>()
}

fn EKUBO_CORE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b>()
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
    contract_address_const::<0x01d6abf4f5963082fc6c44d858ac2e89434406ed682fb63155d146c5d69c22d6>()
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

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

#[derive(Debug, Drop, PartialEq, Serde)]
struct PoolKeyInternal {
    fee: u128,
    tick_spacing: u128,
    extension: felt252,
    sqrt_ratio_limit: u256
}


const AMOUNT_TO_SWAP_STRK: u256 = 1000000000000000000; // 1 STRK
const AMOUNT_TO_SWAP_ETH: u256 = 10000000000000000; // 0.01 ETH 
const MIN_RECEIVED_STRK_TO_STABLE: u256 = 550000; // 0.55 USD stable coin (USDC or USDT)
const MIN_RECEIVED_ETH_TO_STABLE: u256 = 38000000; // 38 USD stable coin (USDC or USDT) 

const FEE_AMOUNT_BPS: u8 = 50; // $0.5 fee
const FEE_AMOUNT: u256 = 50 * 1_000_000 / 100; // $0.5 with 6 decimal

const INITIAL_FEE_TYPE: FeeType = FeeType::Fixed;
const INITIAL_PERCENTAGE_FEE: u16 = 100;
const SUPPORTED_ASSETS_COUNT: u8 = 2;
const PRICE_FEEDS_COUNT: u8 = 2;
const ETH_USD_PRICE_FEED: felt252 = 'ETH/USD';
const STRK_USD_PRICE_FEED: felt252 = 'STRK/USD';


#[derive(Drop, Serde, Clone, Debug)]
enum SwapType {
    strk_usdt,
    strk_usdc,
    eth_usdt,
    eth_usdc
}

//----UTILS----//
fn mag_into(amount: i129) -> u256 {
    amount.mag.into()
}

// util function for swap params
fn swap_param_util(swap_type: SwapType, amount: i129) -> SwapData {
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
                fee: 3402823669209384634633746074317682114,
                tick_spacing: 19802,
                extension: 0,
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

// deployment util function
fn __setup__() -> IAutoSwapprDispatcher {
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


#[test]
#[should_panic(expected: 'Amount is zero')]
fn test_should_revert_if_amount_in_is_zero() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 0, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[should_panic(expected: 'Token not supported')]
fn test_should_revert_if_token0_is_not_supported() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let mut swap_data = swap_param_util(SwapType::strk_usdc, amount);
    swap_data.pool_key.token0 = USDT_TOKEN_ADDRESS(); // unsupported token0
    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: 'u256_sub Overflow')]
fn test_should_revert_if_amountIn_is_greater_than_user_balance() {
    let autoSwappr_dispatcher = __setup__();
    let balance = STRK_TOKEN().balance_of(ADDRESS_WITH_FUNDS());
    let amount = i129 { mag: balance.try_into().unwrap() + 1, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);

    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    cheat_caller_address(strk.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));

    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

    cheat_caller_address(
        autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
    );
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
}

#[test]
#[should_panic(expected: 'CORE_ONLY')]
fn test_should_revert_if_another_address_apart_from_ekubo_core_calls_locked() {
    let autoSwappr_dispatcher = __setup__();
    let locker_dispatcher = ILockerDispatcher {
        contract_address: autoSwappr_dispatcher.contract_address,
    };
    let mock_id = 1;
    let mock_data = array!['mock_data'];
    locker_dispatcher.locked(mock_id, mock_data.span());
}


#[test]
#[fork("MAINNET")]
fn test_strk_for_usdc_swap() {
    let autoSwappr_dispatcher = __setup__();
    let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

    let swap_data = swap_param_util(SwapType::strk_usdc, amount);

    let usdc = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
    let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

    cheat_caller_address(strk.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));

    strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));
    let usdc_initial_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
    let strk_initial_balance = strk.balance_of(ADDRESS_WITH_FUNDS());

    let mut spy = spy_events();
    autoSwappr_dispatcher.ekubo_manual_swap(swap_data);
    // let usdc_final_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
// let strk_final_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
// let min_usdc_received = autoSwappr_dispatcher
//     .get_token_amount_in_usd(strk.contract_address, 1.into())
//     * 1_000_000;

    // assert_eq!(strk_final_balance, strk_initial_balance - mag_into(amount));
// assert_ge!(usdc_final_balance, usdc_initial_balance + min_usdc_received - FEE_AMOUNT);
// assert_eq!(usdc.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
// spy
//     .assert_emitted(
//         @array![
//             (
//                 autoSwappr_dispatcher.contract_address,
//                 Event::SwapSuccessful(
//                     SwapSuccessful {
//                         token_from_address: strk.contract_address,
//                         token_to_address: usdc.contract_address,
//                         token_from_amount: mag_into(amount),
//                         token_to_amount: usdc_final_balance - usdc_initial_balance,
//                         beneficiary: ADDRESS_WITH_FUNDS(),
//                         provider: EKUBO_CORE_ADDRESS()
//                     }
//                 )
//             )
//         ]
//     );
}
// #[test]
// #[fork("MAINNET")]
// fn test_eth_for_usdc_swap() {
//     let autoSwappr_dispatcher = __setup__();
//     let amount = i129 { mag: 10_000_000_000_000_000, sign: false }; // 0.01 ETH

//     let swap_data = swap_param_util(SwapType::eth_usdc, amount);

//     let usdc = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
//     let eth = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };

//     cheat_caller_address(eth.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));

//     eth.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

//     let usdc_initial_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
//     let eth_initial_balance = eth.balance_of(ADDRESS_WITH_FUNDS());

//     cheat_caller_address(
//         autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
//     );
//     let mut spy = spy_events();
//     autoSwappr_dispatcher.ekubo_swap(swap_data);

//     let usdc_final_balance = usdc.balance_of(ADDRESS_WITH_FUNDS());
//     let eth_final_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
//     let min_usdc_received = autoSwappr_dispatcher
//         .get_token_amount_in_usd(eth.contract_address, 1.into())
//         * 10_000; // convert 0.01 ETH to USD with 6 decimals
//     let fee_offset = FEE_AMOUNT;
//     assert_eq!(eth_final_balance, eth_initial_balance - mag_into(amount));
//     assert_ge!(
//         usdc_final_balance, usdc_initial_balance + min_usdc_received - FEE_AMOUNT - fee_offset
//     );
//     assert_eq!(usdc.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
//     spy
//         .assert_emitted(
//             @array![
//                 (
//                     autoSwappr_dispatcher.contract_address,
//                     Event::SwapSuccessful(
//                         SwapSuccessful {
//                             token_from_address: eth.contract_address,
//                             token_to_address: usdc.contract_address,
//                             token_from_amount: mag_into(amount),
//                             token_to_amount: usdc_final_balance - usdc_initial_balance,
//                             beneficiary: ADDRESS_WITH_FUNDS(),
//                             provider: EKUBO_CORE_ADDRESS()
//                         }
//                     )
//                 )
//             ]
//         );
// }

// #[test]
// #[fork("MAINNET")]
// fn test_strk_for_usdt_swap() {
//     let autoSwappr_dispatcher = __setup__();
//     let amount = i129 { mag: 10_000_000_000_000_000_000, sign: false }; // 10 STRK

//     let swap_data = swap_param_util(SwapType::strk_usdt, amount);

//     let usdt = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
//     let strk = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };

//     cheat_caller_address(strk.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));

//     strk.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

//     let usdt_initial_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
//     let strk_initial_balance = strk.balance_of(ADDRESS_WITH_FUNDS());

//     cheat_caller_address(
//         autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
//     );
//     let mut spy = spy_events();
//     autoSwappr_dispatcher.ekubo_swap(swap_data);
//     let usdt_final_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
//     let strk_final_balance = strk.balance_of(ADDRESS_WITH_FUNDS());
//     let min_usdt_received = autoSwappr_dispatcher
//         .get_token_amount_in_usd(strk.contract_address, 10.into())
//         * 1_000_000;
//     assert_eq!(strk_final_balance, strk_initial_balance - mag_into(amount));
//     assert_ge!(usdt_final_balance, usdt_initial_balance + min_usdt_received - FEE_AMOUNT);
//     assert_eq!(usdt.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
//     spy
//         .assert_emitted(
//             @array![
//                 (
//                     autoSwappr_dispatcher.contract_address,
//                     Event::SwapSuccessful(
//                         SwapSuccessful {
//                             token_from_address: strk.contract_address,
//                             token_to_address: usdt.contract_address,
//                             token_from_amount: mag_into(amount),
//                             token_to_amount: usdt_final_balance - usdt_initial_balance,
//                             beneficiary: ADDRESS_WITH_FUNDS(),
//                             provider: EKUBO_CORE_ADDRESS()
//                         }
//                     )
//                 )
//             ]
//         );
// }

// #[test]
// #[fork("MAINNET")]
// fn test_eth_for_usdt_swap() {
//     let autoSwappr_dispatcher = __setup__();
//     let amount = i129 { mag: 10_000_000_000_000_000, sign: false }; // 0.01 ETH

//     let swap_data = swap_param_util(SwapType::eth_usdt, amount);

//     let usdt = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
//     let eth = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };

//     cheat_caller_address(eth.contract_address, ADDRESS_WITH_FUNDS(), CheatSpan::TargetCalls(1));

//     eth.approve(autoSwappr_dispatcher.contract_address, mag_into(amount));

//     let usdt_initial_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
//     let eth_initial_balance = eth.balance_of(ADDRESS_WITH_FUNDS());

//     cheat_caller_address(
//         autoSwappr_dispatcher.contract_address, OPERATOR(), CheatSpan::TargetCalls(1)
//     );
//     let mut spy = spy_events();
//     autoSwappr_dispatcher.ekubo_swap(swap_data);

//     let usdt_final_balance = usdt.balance_of(ADDRESS_WITH_FUNDS());
//     let eth_final_balance = eth.balance_of(ADDRESS_WITH_FUNDS());
//     let min_usdt_received = autoSwappr_dispatcher
//         .get_token_amount_in_usd(eth.contract_address, 1.into())
//         * 10_000; // convert 0.01 ETH to USD with 6 decimals
//     let fee_offset = FEE_AMOUNT;
//     assert_eq!(eth_final_balance, eth_initial_balance - mag_into(amount));
//     assert_ge!(
//         usdt_final_balance, usdt_initial_balance + min_usdt_received - FEE_AMOUNT - fee_offset
//     );
//     assert_eq!(usdt.balance_of(FEE_COLLECTOR.try_into().unwrap()), FEE_AMOUNT);
//     spy
//         .assert_emitted(
//             @array![
//                 (
//                     autoSwappr_dispatcher.contract_address,
//                     Event::SwapSuccessful(
//                         SwapSuccessful {
//                             token_from_address: eth.contract_address,
//                             token_to_address: usdt.contract_address,
//                             token_from_amount: mag_into(amount),
//                             token_to_amount: usdt_final_balance - usdt_initial_balance,
//                             beneficiary: ADDRESS_WITH_FUNDS(),
//                             provider: EKUBO_CORE_ADDRESS()
//                         }
//                     )
//                 )
//             ]
//         );
// }


