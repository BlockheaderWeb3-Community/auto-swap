#[starknet::contract]
mod AutoSwappr {
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::Route;
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry}
    };
    use openzeppelin::access::ownable::OwnableComponent;


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        Ownable_owner: ContractAddress,
    }

    #[event]
    #[derive(starknet::Event, Drop, PartialEq)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.ownable.initializer(get_caller_address());
    }

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
        fn swap_exact_token_to(
            ref self: ContractState,
            token_from_address: ContractAddress,
            token_from_amount: u256,
            token_from_max_amount: u256,
            token_to_address: ContractAddress,
            token_to_amount: u256,
            beneficiary: ContractAddress,
            routes: Array<Route>,
        ) -> bool {
            false
        }
        fn get_fees_active(self: @ContractState) -> bool {
            false
        }
    }
}
