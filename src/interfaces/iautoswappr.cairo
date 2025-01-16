use core::starknet::ContractAddress;
use crate::base::types::Route;
use crate::base::types::{RouteParams, SwapParams};

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
    fn avnu_swap(
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
    fn fibrous_swap(
        ref self: TContractState, routeParams: RouteParams, swapParams: Array<SwapParams>,
    );

    fn collect_fees(
        ref self: TContractState, token_to_received: u256, token_to_address: ContractAddress
    ) -> u256;

    fn contract_parameters(self: @TContractState) -> ContractInfo;
    fn set_operator(ref self: TContractState, address: ContractAddress);
    fn remove_operator(ref self: TContractState, address: ContractAddress);
    fn is_operator(self: @TContractState, address: ContractAddress) -> bool;
    fn get_strk_usd_price(self: @TContractState) -> (u128, u32);
    fn get_eth_usd_price(self: @TContractState) -> (u128, u32);
}

