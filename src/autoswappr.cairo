#[starknet::contract]
mod AutoSwappr {
    use core::starknet::ContractAddress;
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::Route;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(starknet::Event, Drop, PartialEq)]
    enum Event {}

    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
        fn multi_route_swap(
            ref self: ContractState,
            token_from_address: ContractAddress,
            token_from_amount: u256,
            token_to_address: ContractAddress,
            token_to_amount: u256,
            token_to_min_amount: u256,
            beneficiary: ContractAddress,
            integrator_fee_amount_bps: u128,
            integrator_fee_recipient: ContractAddress,
            routes: Array<Route>,
        ) -> bool {
            false
        }
    }
}
