use starknet::ContractAddress;

// @title AVNU Exchange Interface
// @notice Interface for interacting with AVNU's multi-route swap functionality
// @dev Implements core swap functionality with multiple route support and integrator fee system

#[derive(Drop, Serde, Clone)]
struct RouteParam {
    token_in: ContractAddress,
    token_out: ContractAddress,
    amount_in: u256,
    min_received: u256,
    destination: ContractAddress,
}

#[derive(Drop, Serde, Clone)]
struct SwapParams {
    token_in: ContractAddress,
    token_out: ContractAddress,
    rate: u32,
    protocol_id: u32,
    extra_data: Array<felt252>,
}

#[starknet::interface]
pub trait IFibrousExchange<TContractState> {
    #[external(v0)]
    fn swap(ref self: TContractState, route: RouteParam, swap_parameters: Array<SwapParams>);
}
