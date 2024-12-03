#[starknet::contract]
pub mod AutoSwappr {
    use crate::interfaces::iautoswappr::{IAutoSwappr, ContractInfo};
    use crate::base::types::{Route, Assets};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry
    };
    use crate::base::errors::Errors;

    use core::starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_contract_address, ClassHash
    };

    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use core::integer::{u256, u128};
    use core::num::traits::Zero;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        strk_token: ContractAddress,
        eth_token: ContractAddress,
        supported_assets: Map<ContractAddress, bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        fees_collector: ContractAddress,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        avnu_exchange_address: ContractAddress,
    }

    #[event]
    #[derive(starknet::Event, Drop)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
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
        pub block_timestamp: u64
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
        _strk_token: ContractAddress,
        _eth_token: ContractAddress,
        owner: ContractAddress
    ) {
        self.fees_collector.write(fees_collector);
        self.strk_token.write(_strk_token);
        self.eth_token.write(_eth_token);
        self.avnu_exchange_address.write(avnu_exchange_address);
        self.ownable.initializer(owner);
        self.supported_assets.write(_strk_token, true);
        self.supported_assets.write(_eth_token, true);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
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
            let caller_address = get_caller_address();

            assert(
                self.supported_assets.entry(token_from_address).read(), Errors::UNSUPPORTED_TOKEN
            );
            assert(!token_from_amount.is_zero(), Errors::ZERO_AMOUNT);

            let token = IERC20Dispatcher { contract_address: token_from_address };

            assert(
                token.balance_of(caller_address) >= token_from_amount, Errors::INSUFFICIENT_BALANCE
            );
            assert(
                token.allowance(caller_address, this_contract) >= token_from_amount,
                Errors::INSUFFICIENT_ALLOWANCE
            );

            let transfer = token.transfer_from(caller_address, this_contract, token_from_amount);
            assert(transfer, Errors::TRANSFER_FAILED);

            let approval = token.approve(self.avnu_exchange_address.read(), token_from_amount);
            assert(approval, Errors::APPROVAL_FAILED);

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


        fn contract_parameters(self: @ContractState) -> ContractInfo {
            ContractInfo {
                fees_collector: self.fees_collector.read(),
                avnu_exchange_address: self.avnu_exchange_address.read(),
                strk_token: self.strk_token.read(),
                eth_token: self.eth_token.read(),
                owner: self.ownable.owner()
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
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
}
