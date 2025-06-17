// starknet imports
use starknet::{ContractAddress, contract_address_const};
// OZ imports
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use auto_swappr::base::types::{FeeType, Route};

use auto_swappr::interfaces::ioperator::{IOperatorDispatcher, IOperatorDispatcherTrait};

pub const FEE_COLLECTOR: felt252 =
    0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;

pub fn AVNU_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f>()
}

pub fn FIBROUS_EXCHANGE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a>()
}

pub fn EKUBO_CORE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b>()
}

pub fn STRK_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

pub fn ETH_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
}

pub fn USDC_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x053C91253BC9682c04929cA02ED00b3E423f6710D2ee7e0D5EBB06F3eCF368A8>()
}

pub fn USDT_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x068F5c6a61780768455de69077E07e89787839bf8166dEcfBf92B645209c0fB8>()
}


pub fn ADDRESS_WITH_FUNDS() -> ContractAddress {
    contract_address_const::<0x04164013f90b05d67f026779bf96e9c401c96f3485b645a786166e6935fba116>()
}

pub fn JEDISWAP_POOL_ADDRESS() -> ContractAddress {
    contract_address_const::<0x5726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26>()
}

pub fn STRK_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() }
}

pub fn ETH_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() }
}

pub fn USDT_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() }
}

pub fn USDC_TOKEN() -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() }
}

pub fn ORACLE_ADDRESS() -> ContractAddress {
    contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>()
}


pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}

pub fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

pub fn OPERATOR_DISPATCHER() -> IOperatorDispatcher {
    IOperatorDispatcher { contract_address: FEE_COLLECTOR_ADDRESS() }
}

pub fn FEE_COLLECTOR_ADDRESS() -> ContractAddress {
    contract_address_const::<0x7f5a528821f37c06375a47a1c8d2ba0517a2e99ff01c01ef5068e3fb3754b87>()
}

#[derive(Debug, Drop, PartialEq, Serde)]
pub struct PoolKeyInternal {
    pub fee: u128,
    pub tick_spacing: u128,
    pub extension: felt252,
    pub sqrt_ratio_limit: u256
}

#[derive(Drop, Serde, Clone, Debug)]
pub struct WalletAmounts {
    pub strk: u256,
    pub eth: u256,
    pub usdt: u256,
    pub usdc: u256,
}

#[derive(Drop, Serde, Debug)]
pub struct AVNUParams {
    pub token_from_address: ContractAddress,
    pub token_from_amount: u256,
    pub token_to_address: ContractAddress,
    pub token_to_min_amount: u256,
    pub beneficiary: ContractAddress,
    pub integrator_fee_amount_bps: u128,
    pub integrator_fee_recipient: ContractAddress,
    pub routes: Array<Route>,
}

#[derive(Drop, Serde, Clone, Debug)]
pub enum SwapType {
    strk_usdt,
    strk_usdc,
    eth_usdt,
    eth_usdc
}


pub const AMOUNT_TO_SWAP_STRK: u256 = 1000000000000000000; // 1 STRK
pub const AMOUNT_TO_SWAP_ETH: u256 = 10000000000000000; // 0.01 ETH 
pub const MIN_RECEIVED_STRK_TO_STABLE: u256 = 550000; // 0.55 USD stable coin (USDC or USDT)
pub const MIN_RECEIVED_ETH_TO_STABLE: u256 = 38000000; // 38 USD stable coin (USDC or USDT) 

pub const FEE_AMOUNT_BPS: u8 = 50; // $0.5 fee
pub const FEE_AMOUNT: u256 = 50 * 1_000_000 / 100; // $0.5 with 6 decimal

pub const INITIAL_FEE_TYPE: FeeType = FeeType::Fixed;
pub const INITIAL_PERCENTAGE_FEE: u16 = 100;
pub const SUPPORTED_ASSETS_COUNT: u8 = 2;
pub const PRICE_FEEDS_COUNT: u8 = 2;
pub const ETH_USD_PRICE_FEED: felt252 = 'ETH/USD';
pub const STRK_USD_PRICE_FEED: felt252 = 'STRK/USD';

pub const SUBSTRACT_VALUE_FOR_MIN_AMOUNT_MARGIN: u256 = 1000;
pub const ROUTES_PERCENT: u128 = 1000000000000;
pub const INTEGRATOR_FEE_AMOUNT: u128 = 0;

////////AVNU Swap constants//////////
pub fn INTEGRATOR_FEE_RECIPIENT() -> ContractAddress {
    contract_address_const::<0>()
}

pub fn EXCHANGE_STRK_USDT() -> ContractAddress {
    contract_address_const::<
        0x359550b990167afd6635fa574f3bdadd83cb51850e1d00061fe693158c23f80
    >() // jedi swap: swap router v2
}
pub fn EXCHANGE_STRK_USDT_POOL() -> ContractAddress {
    // Sometimes the exchange contract takes the currencies to swap from another contract, in this
    // case, the first address of the route extra params
    contract_address_const::<
        0xb74193526135104973a1e285bb0372adf41a5d7a8fc5e6f30ea535847613ce
    >() // jedi swap: swap router v2
}

pub fn EXCHANGE_STRK_USDC() -> ContractAddress {
    contract_address_const::<
        0x41fd22b238fa21cfcf5dd45a8548974d8263b3a531a60388411c5e230f97023
    >() // jedi swap: AMM swap
}

pub fn EXCHANGE_STRK_USDC_POOL() -> ContractAddress {
    contract_address_const::<
        0x05726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26
    >() // jedi swap: AMM swap
}

pub fn EXCHANGE_ETH_USDT_POOL() -> ContractAddress {
    contract_address_const::<0x0351d125294ae90c5ac53405ebc491d5d910e4f903cdc5d8c0d342dfa71fd0e9>()
}

pub fn EXCHANGE_ETH_USDT_SITH() -> ContractAddress {
    contract_address_const::<
        0x28c858a586fa12123a1ccb337a0a3b369281f91ea00544d0c086524b759f627
    >() // sith swap: AMM router
}

pub fn EXCHANGE_ETH_USDT_EKUBO() -> ContractAddress {
    contract_address_const::<
        158098919692956613592021320609952044916245725306097615271255138786123
    >() // EKUBO core
}

pub fn EXCHANGE_ETH_USDC() -> ContractAddress {
    contract_address_const::<
        0x1114c7103e12c2b2ecbd3a2472ba9c48ddcbf702b1c242dd570057e26212111
    >() // myswap: CL AMM swap
}
