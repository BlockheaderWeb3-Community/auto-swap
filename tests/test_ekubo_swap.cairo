// *************************************************************************
//                              EKUBO SWAP TEST
// *************************************************************************
// starknet imports
use starknet::{ContractAddress, contract_address_const};

// snforge imports
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, cheat_caller_address, CheatSpan
};

// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Autoswappr imports
use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{FeeType, SwapData};
use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};

// Ekubo imports
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use ekubo::interfaces::core::SwapParameters;


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

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

mod pool_key {
    pub const FEE: u128 = 170141183460469235273462165868118016;
    pub const TICK_SPACING: u128 = 1000;
    pub const EXTENSION: felt252 = 0;
    pub const SQRT_RATIO_LIMIT: u256 = 18446748437148339061; // min sqrt ratio limit
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

// util function for swap params
fn swap_param_util(swap_type: SwapType, amount: i129) -> SwapData {
    let swap_params = SwapParameters {
        amount, sqrt_ratio_limit: pool_key::SQRT_RATIO_LIMIT, is_token1: false, skip_ahead: 0
    };
    match swap_type {
        SwapType::strk_usdc => {
            let pool_key = PoolKey {
                token0: STRK_TOKEN_ADDRESS(),
                token1: USDC_TOKEN_ADDRESS(),
                fee: pool_key::FEE,
                tick_spacing: pool_key::TICK_SPACING,
                extension: pool_key::EXTENSION.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };

            swap_data
        },
        SwapType::strk_usdt => {
            let pool_key = PoolKey {
                token0: STRK_TOKEN_ADDRESS(),
                token1: USDT_TOKEN_ADDRESS(),
                fee: pool_key::FEE,
                tick_spacing: pool_key::TICK_SPACING,
                extension: pool_key::EXTENSION.try_into().unwrap()
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
                fee: pool_key::FEE,
                tick_spacing: pool_key::TICK_SPACING,
                extension: pool_key::EXTENSION.try_into().unwrap()
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
                fee: pool_key::FEE,
                tick_spacing: pool_key::TICK_SPACING,
                extension: pool_key::EXTENSION.try_into().unwrap()
            };

            let swap_data = SwapData {
                params: swap_params, pool_key, caller: ADDRESS_WITH_FUNDS()
            };
            swap_data
        }
    }
}
