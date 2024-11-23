use core::starknet::ContractAddress;

#[derive(Drop, Serde, Clone)]
pub struct Route {
    token_from: ContractAddress,
    token_to: ContractAddress,
    exchange_address: ContractAddress,
    percent: u128,
    additional_swap_params: Array<felt252>,
}

#[derive(Drop, Serde, Clone)]
pub struct Assets {
    pub strk: bool,
    pub eth: bool
}