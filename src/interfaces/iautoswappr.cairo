use core::starknet::ContractAddress;
use crate::base::types::{Route, Assets};

#[derive(Copy, Debug, Drop, PartialEq, Serde)]
pub struct ContractInfo {
    pub fees_collector: ContractAddress,
    pub avnu_exchange_address: ContractAddress,
    pub fibrous_exchange_address: ContractAddress,
    pub strk_token: ContractAddress,
    pub eth_token: ContractAddress,
    pub owner: ContractAddress
}

#[starknet::interface]
pub trait IAutoSwappr<TContractState> {
    fn swap(
        ref self: TContractState,
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_amount: u256,
        token_to_min_amount: u256,
        beneficiary: ContractAddress,
        integrator_fee_amount_bps: u128,
        integrator_fee_recipient: ContractAddress,
        routes: Array<Route>,
    );

    fn contract_parameters(self: @TContractState) -> ContractInfo;
    fn set_operator(ref self: TContractState, address: ContractAddress);
    fn remove_operator(ref self: TContractState, address: ContractAddress);
}

