#[starknet::contract]
mod AutoSwappr {
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::{Route, Assets};
    use crate::base::errors::Errors;
    use core::starknet::{
        ContractAddress, get_caller_address, get_contract_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry}
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::integer::{u256, u128};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        fees_collector: ContractAddress,
        strk_token: ContractAddress,
        eth_token: ContractAddress,
    }

    #[event]
    #[derive(starknet::Event, Drop)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Subscribed: Subscribed,
    }

    #[derive(starknet::Event, Drop)]
    struct Subscribed {
        user: ContractAddress,
        assets: Assets,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        fees_collector: ContractAddress,
        strk_token: ContractAddress,
        eth_token: ContractAddress
    ) {
        self.ownable.initializer(get_caller_address());
        self.fees_collector.write(fees_collector);
        self.strk_token.write(strk_token);
        self.eth_token.write(eth_token);
    }

    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
        fn subscribe(ref self: ContractState, assets: Assets) {
            let caller = get_caller_address();
            assert(is_non_zero(caller), Errors::ZERO_ADDRESS_CALLER);

            let max_u256 = u256 {
                low: 0xffffffffffffffffffffffffffffffff, high: 0xffffffffffffffffffffffffffffffff
            };

            if assets.strk {
                let strk_token_address = self.strk_token.read();
                let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
                strk_token.approve(get_contract_address(), max_u256);
            }

            if assets.eth {
                let eth_token_address = self.eth_token.read();
                let eth_token = IERC20Dispatcher { contract_address: eth_token_address };
                eth_token.approve(get_contract_address(), max_u256);
            }

            self.emit(Subscribed { user: caller, assets });
        }

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
        ) {}
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

    fn is_non_zero(address: ContractAddress) -> bool {
        address.into() != 0
    }
}
