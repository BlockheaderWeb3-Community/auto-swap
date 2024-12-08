use starknet::ContractAddress;
use crate::base::types::Route;

// @title AVNU Exchange Interface
// @notice Interface for interacting with AVNU's multi-route swap functionality
// @dev Implements core swap functionality with multiple route support and integrator fee system
#[starknet::interface]
pub trait IExchange<TContractState> {
    fn multi_route_swap(
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
    ) -> bool;
}
