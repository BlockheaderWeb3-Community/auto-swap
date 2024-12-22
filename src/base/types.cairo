use core::starknet::ContractAddress;

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
