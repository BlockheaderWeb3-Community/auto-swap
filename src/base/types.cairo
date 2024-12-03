use core::starknet::ContractAddress;

#[derive(Drop, Serde, Clone)]
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
