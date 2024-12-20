use crate::base::types::{RouteParams, SwapParams};

#[starknet::interface]
pub trait IFibrousExchange<TContractState> {
    #[external(v0)]
    fn swap(ref self: TContractState, route: RouteParams, swap_parameters: Array<SwapParams>);
}
