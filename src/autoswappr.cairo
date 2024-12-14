#[starknet::contract]
// @title AutoSwappr Contract
// @notice Facilitates automated token swaps through AVNU Exchange integration
// @dev Implements upgradeable pattern and ownership control
pub mod AutoSwappr {
    use crate::interfaces::iautoswappr::{IAutoSwappr, ContractInfo};
    use crate::base::types::{Route, Assets, RouteParams, SwapParams};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry,
    };
    use crate::base::errors::Errors;

    use core::starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_contract_address,
        ClassHash,
    };

    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};
    use crate::interfaces::fibrous_exchange::{IFibrousExchangeDispatcher, IFibrousExchangeDispatcherTrait};
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
        supported_assets: Map<ContractAddress, bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        fees_collector: ContractAddress,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        avnu_exchange_address: ContractAddress,
        fibrous_exchange_address: ContractAddress,
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
        Unsubscribed: Unsubscribed,
    }

    // @notice Event emitted when a swap is successfully executed
    // @param token_from_address Address of the token being sold
    // @param token_from_amount Amount of tokens being sold
    // @param token_to_address Address of the token being bought
    // @param token_to_amount Amount of tokens being bought
    // @param beneficiary Address receiving the bought tokens
    #[derive(Drop, starknet::Event)]
    struct SwapSuccessful {
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_amount: u256,
        beneficiary: ContractAddress,
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
        pub block_timestamp: u64,
    }

    // @notice Constructor to initialize the contract
    // @param fees_collector Address where fees will be collected
    // @param avnu_exchange_address Address of the AVNU exchange
    // @param _strk_token Address of the STRK token
    // @param _eth_token Address of the ETH token
    // @param owner Address of the contract owner
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
        self.avnu_exchange_address.write(avnu_exchange_address);
        self.fibrous_exchange_address.write(fibrous_exchange_address);
        self.ownable.initializer(owner);
        self.supported_assets.write(_strk_token, true);
        self.supported_assets.write(_eth_token, true);
    }

    // @notice Upgrades the contract implementation
    // @dev Only callable by contract owner
    // @param new_class_hash The new implementation hash to upgrade to
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
        // @notice Executes a token swap through AVNU exchange
        // @dev Requires approval for token_from_address
        // @param token_from_address Address of token to sell
        // @param token_from_amount Amount of tokens to sell
        // @param token_to_address Address of token to buy
        // @param token_to_amount Expected amount of tokens to receive
        // @param token_to_min_amount Minimum acceptable amount of tokens to receive
        // @param beneficiary Address to receive the bought tokens
        // @param integrator_fee_amount_bps Fee amount in basis points
        // @param integrator_fee_recipient Address to receive the integration fee
        // @param routes Array of routes for the swap
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
                self.supported_assets.entry(token_from_address).read(), Errors::UNSUPPORTED_TOKEN,
            );
            assert(!token_from_amount.is_zero(), Errors::ZERO_AMOUNT);

            let token = IERC20Dispatcher { contract_address: token_from_address };

            assert(
                token.balance_of(caller_address) >= token_from_amount, Errors::INSUFFICIENT_BALANCE,
            );
            assert(
                token.allowance(caller_address, this_contract) >= token_from_amount,
                Errors::INSUFFICIENT_ALLOWANCE,
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
                    routes,
                );

            assert(swap, Errors::SWAP_FAILED);

            self
                .emit(
                    SwapSuccessful {
                        token_from_address,
                        token_from_amount,
                        token_to_address,
                        token_to_amount,
                        beneficiary,
                    },
                );
        }

        fn fibrous_swap(
            ref self: ContractState,
            routeParams: RouteParams,
            swapParams: Array<SwapParams>,
        ){
            let caller_address = get_caller_address();
            // let this_contract = get_contract_address();

            assert(
                self.supported_assets.entry(routeParams.token_in).read(), Errors::UNSUPPORTED_TOKEN,
            );
            assert(!routeParams.amount_in.is_zero(), Errors::ZERO_AMOUNT);

            let token = IERC20Dispatcher { contract_address: routeParams.token_in };

            assert(
                token.balance_of(caller_address) >= routeParams.amount_in, Errors::INSUFFICIENT_BALANCE,
            );
            // should check for ETH, not amount in token 
            // assert( 
            //     token.allowance(caller_address, this_contract) >= routeParams.amount_in,
            //     Errors::INSUFFICIENT_ALLOWANCE,
            // );
                let eth_token = IERC20Dispatcher { contract_address: contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>() };

                eth_token
                .approve(
                    self.fibrous_exchange_address.read(),
                    20000000000000000000
                );

            self
                ._fibrous_swap(
                    routeParams,
                    swapParams,
                );
        }


        // @notice Returns the contract's current parameters
        // @return ContractInfo struct containing current contract parameters
        fn contract_parameters(self: @ContractState) -> ContractInfo {
            ContractInfo {
                fees_collector: self.fees_collector.read(),
                avnu_exchange_address: self.avnu_exchange_address.read(),
                strk_token: self.strk_token.read(),
                eth_token: self.eth_token.read(),
                owner: self.ownable.owner(),
            }
        }
    }

    // @dev Internal implementation trait
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // @notice Internal function to execute the swap through AVNU exchange
        // @dev Called by the public swap function after validations
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
                    routes,
                )
        }

        fn _fibrous_swap(
            ref self: ContractState,
            routeParams: RouteParams,
            swapParams: Array<SwapParams>,
        ) {
            let fibrous = IFibrousExchangeDispatcher { contract_address: self.fibrous_exchange_address.read() };

            fibrous
                .swap(
                    routeParams, 
                    swapParams
                );
        }

        fn collect_fees(ref self: ContractState) {}

        // @notice Returns the zero address constant
        fn zero_address(self: @ContractState) -> ContractAddress {
            contract_address_const::<0>()
        }
    }
}
