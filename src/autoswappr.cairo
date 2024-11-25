#[starknet::contract]
pub mod AutoSwappr {
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::{Route, Assets};
    use crate::base::errors::Errors;

    use core::starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_contract_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry}
    };

    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};
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
        avnu_exchange_address: ContractAddress,
        strk_token: ContractAddress,
        eth_token: ContractAddress,
    }

    #[event]
    #[derive(starknet::Event, Drop)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        SwapSuccessful: SwapSuccessful,
        Subscribed: Subscribed,
        Unsubscribed: Unsubscribed
    }

    #[derive(Drop, starknet::Event)]
    struct SwapSuccessful {
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_amount: u256,
        beneficiary: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    struct Subscribed {
        user: ContractAddress,
        assets: Assets,
    }

    #[derive(starknet::Event, Drop)]
    pub struct Unsubscribed {
        pub user: ContractAddress,
        pub assets: Assets,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
        strk_token: ContractAddress,
        eth_token: ContractAddress
    ) {
        self.ownable.initializer(get_caller_address());
        self.fees_collector.write(fees_collector);
        self.strk_token.write(strk_token);
        self.eth_token.write(eth_token);
        self.avnu_exchange_address.write(avnu_exchange_address);
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

        fn unsubscribe(ref self: ContractState, assets: Assets) {
            let caller = get_caller_address();
            assert(is_non_zero(caller), Errors::ZERO_ADDRESS_CALLER);

            if assets.strk {
                let strk_token_address = self.strk_token.read();
                let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
                strk_token.approve(get_contract_address(), 0);
                assert(!self.is_approved(caller, strk_token_address), Errors::UNSUBSCRIBE_FAILED);
            }

            if assets.eth {
                let eth_token_address = self.eth_token.read();
                let eth_token = IERC20Dispatcher { contract_address: eth_token_address };
                eth_token.approve(get_contract_address(), 0);
                assert(!self.is_approved(caller, eth_token_address), Errors::UNSUBSCRIBE_FAILED);
            }

            self.emit(Unsubscribed { user: caller, assets });
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
        ) {
            let this_contract = get_contract_address();

            assert(
                self.is_approved(this_contract, token_from_address), Errors::SPENDER_NOT_APPROVED
            );

            let swap = self
                ._swap(
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
            let token = IERC20Dispatcher { contract_address: token_contract };
            token.allowance(beneficiary, get_contract_address()) > 0
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
            let avnu = IExchangeDispatcher { contract_address: self.avnu_exchange_address.read() };

            avnu
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
                )
        }

        fn collect_fees(ref self: ContractState) {}

        fn zero_address(self: @ContractState) -> ContractAddress {
            contract_address_const::<0>()
        }
    }

    fn is_non_zero(address: ContractAddress) -> bool {
        address.into() != 0
    }
}
