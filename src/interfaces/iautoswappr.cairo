use core::starknet::ContractAddress;
use crate::base::types::Route;
use crate::base::types::{RouteParams, SwapParams};

#[derive(Copy, Debug, Drop, PartialEq, Serde)]
pub struct ContractInfo {
    pub fees_collector: ContractAddress,
    pub avnu_exchange_address: ContractAddress,
    pub fibrous_exchange_address: ContractAddress,
    pub oracle_address: ContractAddress,
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
        beneficiary: ContractAddress,
        integrator_fee_amount_bps: u128,
        integrator_fee_recipient: ContractAddress,
        routes: Array<Route>,
    );
    fn fibrous_swap(
        ref self: TContractState,
        routeParams: RouteParams,
        swapParams: Array<SwapParams>,
        beneficiary: ContractAddress,
    );

    fn contract_parameters(self: @TContractState) -> ContractInfo;
    fn set_operator(ref self: TContractState, address: ContractAddress);
    fn remove_operator(ref self: TContractState, address: ContractAddress);
    fn is_operator(self: @TContractState, address: ContractAddress) -> bool;
    fn support_new_token_from(
        ref self: TContractState, token_from: ContractAddress, feed_id: felt252
    );
    fn remove_token_from(ref self: TContractState, token_from: ContractAddress);
    fn get_token_amount_in_usd(
        self: @TContractState, token: ContractAddress, token_amount: u256
    ) -> u256;
    fn get_token_from_status_and_value(
        self: @TContractState, token_from: ContractAddress
    ) -> (bool, felt252);
}

