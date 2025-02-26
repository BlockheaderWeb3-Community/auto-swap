use core::starknet::ContractAddress;
use crate::base::types::Route;
use crate::base::types::{RouteParams, SwapParams, FeeType};

#[derive(Copy, Debug, Drop, PartialEq, Serde)]
pub struct ContractInfo {
    pub fees_collector: ContractAddress,
    pub fibrous_exchange_address: ContractAddress,
    pub avnu_exchange_address: ContractAddress,
    pub oracle_address: ContractAddress,
    pub owner: ContractAddress,
    pub fee_type: FeeType,
    pub percentage_fee: u16
}

#[starknet::interface]
pub trait IAutoSwappr<TContractState> {
    fn avnu_swap(
        ref self: TContractState,
        token_sender: ContractAddress,
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_min_amount: u256,
        beneficiary: ContractAddress,
        integrator_fee_amount_bps: u128,
        integrator_fee_recipient: ContractAddress,
        routes: Array<Route>,
    );
    fn fibrous_swap(
        ref self: TContractState,
        routeParams: RouteParams,
        swapParams: Array<SwapParams>,
        token_sender: ContractAddress,
        beneficiary: ContractAddress,
    );

    fn contract_parameters(self: @TContractState) -> ContractInfo;

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
    fn set_fee_type(ref self: TContractState, fee_type: FeeType, percentage_fee: u16);
}

