use core::starknet::ContractAddress;
use crate::base::types::Route;

// @title Contract Information Structure
// @notice Holds the essential addresses and parameters for the AutoSwappr contract
// @dev This struct is used to return the contract's configuration in a single call
#[derive(Copy, Debug, Drop, PartialEq, Serde)]
pub struct ContractInfo {
    pub fees_collector: ContractAddress,
    pub avnu_exchange_address: ContractAddress,
    pub strk_token: ContractAddress,
    pub eth_token: ContractAddress,
    pub owner: ContractAddress,
}

// @title IAutoSwappr Interface
// @notice Interface defining the main functionality of the AutoSwappr contract
// @dev Implements token swapping functionality through AVNU Exchange
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

    // @notice Retrieves the current contract parameters
    // @return ContractInfo struct containing the contract's current configuration
    fn contract_parameters(self: @TContractState) -> ContractInfo;
}
