#[starknet::contract]
mod AutoSwappr {
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::{Route, Assets};
    use crate::base::errors::Errors;
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry}
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
    }

    #[event]
    #[derive(starknet::Event, Drop)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        SwapSuccessful: SwapSuccessful,
    }

    #[derive(Drop, starknet::Event)]
    struct SwapSuccessful {
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_amount: u256,
        beneficiary: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress
    ) {
        self.ownable.initializer(get_caller_address());
        self.fees_collector.write(fees_collector);
        self.avnu_exchange_address.write(avnu_exchange_address);
    }

    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
        fn subscribe(ref self: ContractState, assets: Assets) {}

        fn swap(
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
        ) {
            let avnu = IExchangeDispatcher { contract_address: self.avnu_exchange_address.read() };

            let swap = avnu
                .multi_route_swap(
                    token_from_address,
                    token_from_amount,
                    token_to_address,
                    token_to_amount,
                    token_to_min_amount,
                    beneficiary,
                    integrator_fee_amount_bps,
                    integrator_fee_recipient,
                    routes
                );

            assert(swap, Errors::SWAP_FAILED);

            self
                .emit(
                    SwapSuccessful {
                        token_from_address,
                        token_from_amount,
                        token_to_address,
                        token_to_amount,
                        beneficiary
                    }
                );
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn is_approved(
            self: @ContractState, beneficiary: ContractAddress, token_contract: ContractAddress
        ) -> bool {
            false
        }

        fn _swap(
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

        fn collect_fees(ref self: ContractState) {}
    }
}
