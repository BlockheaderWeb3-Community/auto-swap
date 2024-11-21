use core::starknet::ContractAddress;
use crate::base::types::{Route, Assets};

#[starknet::interface]
pub trait IAutoSwappr<TContractState> {
    fn subscribe(ref self: TContractState, assets: Assets);

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
}
