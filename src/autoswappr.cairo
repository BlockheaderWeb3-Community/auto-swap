#[starknet::contract]
// @title AutoSwappr Contract
// @dev Implements upgradeable pattern and ownership control
pub mod AutoSwappr {
    use crate::interfaces::iautoswappr::{IAutoSwappr, ContractInfo};
    use crate::base::types::{Route, Assets, RouteParams, SwapParams};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry
    };
    use crate::base::errors::Errors;

    use core::starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_contract_address, ClassHash
    };

    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};
    use crate::interfaces::ifibrous_exchange::{
        IFibrousExchangeDispatcher, IFibrousExchangeDispatcherTrait
    };
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use core::integer::{u256, u128};
    use core::num::traits::Zero;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // @notice Storage struct containing all contract state variables
    // @dev Includes mappings for supported assets and critical contract addresses
    #[storage]
    struct Storage {
        strk_token: ContractAddress,
        eth_token: ContractAddress,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
        fibrous_exchange_address: ContractAddress,
        supported_assets: Map<ContractAddress, bool>,
        autoswappr_addresses: Map<ContractAddress, bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    // @notice Events emitted by the contract

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
    // @notice Event emitted when a swap is successfully executed
    // @param token_from_address Address of the token being sold
    // @param token_from_amount Amount of tokens being sold
    // @param token_to_address Address of the token being bought
    // @param token_to_amount Amount of tokens being bought
    // @param beneficiary Address receiving the bought tokens
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
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
        fibrous_exchange_address: ContractAddress,
        _strk_token: ContractAddress,
        _eth_token: ContractAddress,
        owner: ContractAddress,
    ) {
        self.fees_collector.write(fees_collector);
        self.strk_token.write(_strk_token);
        self.eth_token.write(_eth_token);
        self.fibrous_exchange_address.write(fibrous_exchange_address);
        self.avnu_exchange_address.write(avnu_exchange_address);
        self.fibrous_exchange_address.write(fibrous_exchange_address);
        self.ownable.initializer(owner);
        self.supported_assets.entry(_strk_token).write(true);
        self.supported_assets.entry(_eth_token).write(true);
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
            assert(
                self.autoswappr_addresses.entry(get_caller_address()).read() == true,
                Errors::INVALID_SENDER
            );

            assert(!token_from_amount.is_zero(), Errors::ZERO_AMOUNT);
            assert(
                self.check_if_token_from_is_supported(token_from_address), Errors::UNSUPPORTED_TOKEN
            );

            let this_contract = get_contract_address();
            let token_from_contract = IERC20Dispatcher { contract_address: token_from_address };
            let token_to_contract = IERC20Dispatcher { contract_address: token_to_address };
            let contract_token_to_balance = token_to_contract.balance_of(this_contract);

            assert(
                token_from_contract
                    .allowance(get_caller_address(), this_contract) >= token_from_amount,
                Errors::INSUFFICIENT_ALLOWANCE,
            );

            token_from_contract
                .transfer_from(get_caller_address(), this_contract, token_from_amount);
            token_from_contract.approve(self.avnu_exchange_address.read(), token_from_amount);

            let swap = self
                ._swap(
                    token_from_address,
                    token_from_amount,
                    token_to_address,
                    token_to_amount,
                    token_to_min_amount,
                    // beneficiary,
                    this_contract, // only caller address can be the beneficiary, in this case, the contract. 
                    integrator_fee_amount_bps,
                    integrator_fee_recipient,
                    routes
                );
            assert(swap, Errors::SWAP_FAILED);

            let new_contract_token_to_balance = token_to_contract.balance_of(this_contract);
            let mut token_to_received = new_contract_token_to_balance - contract_token_to_balance;
            token_to_contract.transfer(beneficiary, token_to_received);

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

        fn fibrous_swap(
            ref self: ContractState, routeParams: RouteParams, swapParams: Array<SwapParams>,
        ) {
            let caller_address = get_caller_address();
            let contract_address = get_contract_address();

            // assertions
            assert(
                self.supported_assets.entry(routeParams.token_in).read(), Errors::UNSUPPORTED_TOKEN,
            );
            assert(!routeParams.amount_in.is_zero(), Errors::ZERO_AMOUNT);

            let token = IERC20Dispatcher { contract_address: routeParams.token_in };
            assert(
                token.allowance(caller_address, contract_address) >= routeParams.amount_in,
                Errors::INSUFFICIENT_ALLOWANCE,
            );

            // Approve commission taking from fibrous
            let token = IERC20Dispatcher { contract_address: routeParams.token_in };
            token.transfer_from(caller_address, contract_address, routeParams.amount_in);
            token.approve(self.fibrous_exchange_address.read(), routeParams.amount_in);

            self._fibrous_swap(routeParams, swapParams,);
        }

        fn set_operator(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self.ownable.owner(), Errors::NOT_OWNER);
            assert(
                self.autoswappr_addresses.entry(address).read() == false, Errors::EXISTING_ADDRESS
            );
            self.autoswappr_addresses.entry(address).write(true);
        }

        fn remove_operator(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self.ownable.owner(), Errors::NOT_OWNER);
            assert(
                self.autoswappr_addresses.entry(address).read() == true,
                Errors::NON_EXISTING_ADDRESS
            );
            self.autoswappr_addresses.entry(address).write(false);
        }


        fn contract_parameters(self: @ContractState) -> ContractInfo {
            ContractInfo {
                fees_collector: self.fees_collector.read(),
                fibrous_exchange_address: self.fibrous_exchange_address.read(),
                avnu_exchange_address: self.avnu_exchange_address.read(),
                strk_token: self.strk_token.read(),
                eth_token: self.eth_token.read(),
                owner: self.ownable.owner()
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn check_if_token_from_is_supported(
            self: @ContractState, token_from: ContractAddress
        ) -> bool {
            self.supported_assets.entry(token_from).read()
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

        fn _fibrous_swap(
            ref self: ContractState, routeParams: RouteParams, swapParams: Array<SwapParams>,
        ) {
            let fibrous = IFibrousExchangeDispatcher {
                contract_address: self.fibrous_exchange_address.read()
            };

            fibrous.swap(routeParams, swapParams);
        }

        fn collect_fees(ref self: ContractState) {}

        // @notice Returns the zero address constant
        fn zero_address(self: @ContractState) -> ContractAddress {
            contract_address_const::<0>()
        }
    }

    fn is_non_zero(address: ContractAddress) -> bool {
        address.into() != 0
    }
}
