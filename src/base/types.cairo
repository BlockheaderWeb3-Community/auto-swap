use core::starknet::ContractAddress;
use ekubo::interfaces::core::SwapParameters;
use ekubo::types::keys::PoolKey;
use ekubo::types::delta::Delta;


#[derive(Debug, Drop, PartialEq, Serde)]
pub struct Route {
    pub token_from: ContractAddress,
    pub token_to: ContractAddress,
    pub exchange_address: ContractAddress,
    pub percent: u128,
    pub additional_swap_params: Array<felt252>,
}

#[derive(Drop, Serde, Clone, Debug)]
pub struct Assets {
    pub strk: bool,
    pub eth: bool
}

// Fibrous exchange
#[derive(Drop, Serde, Clone)]
pub struct RouteParams {
    pub token_in: ContractAddress,
    pub token_out: ContractAddress,
    pub amount_in: u256,
    pub min_received: u256,
    pub destination: ContractAddress,
}

#[derive(Drop, Serde, Clone)]
pub struct SwapParams {
    pub token_in: ContractAddress,
    pub token_out: ContractAddress,
    pub rate: u32,
    pub protocol_id: u32,
    pub pool_address: ContractAddress,
    pub extra_data: Array<felt252>,
}

#[derive(Copy, Drop, Debug, PartialEq, Serde, Clone, starknet::Store)]
pub enum FeeType {
    Fixed,
    Percentage
}

#[derive(Copy, Drop, Debug, PartialEq, Serde, Clone, starknet::Store)]
pub enum Token {
    STRK,
    USDT,
}


// Ekubo structs
#[derive(Copy, Drop, Serde)]
pub struct SwapData {
    pub params: SwapParameters,
    pub pool_key: PoolKey,
    pub caller: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
pub struct SwapResult {
    pub delta: Delta,
}
