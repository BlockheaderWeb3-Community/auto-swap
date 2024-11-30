#[starknet::contract]
/// @title AutoSwappr - Automated token swapping contract
/// @notice Provides functionality for automated token swaps using AVNU Exchange
/// @dev Implements upgradeable and ownable functionality
mod AutoSwappr {
    /// @notice Importing interfaces and utilities for token swapping and contract management.
    use crate::interfaces::autoswappr::IAutoSwappr;
    use crate::base::types::{Route, Assets};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;

    use crate::base::errors::Errors;

    use core::starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_contract_address, ClassHash
    };

    use openzeppelin::access::ownable::OwnableComponent;
    use crate::interfaces::iavnu_exchange::{IExchangeDispatcher, IExchangeDispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use core::integer::{u256, u128};

    /// @notice Contract components for ownership and upgradeability management
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    /// @notice Implement ownership functionality for the contract
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    /// @notice Implement internal ownership-related logic for the contract
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// @notice Implement internal upgradeability-related logic for the contract
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    /// @notice Contract storage structure
    /// @dev Contains addresses for fees collection and token contracts
    #[storage]
    struct Storage {
        /// @notice Ownable component storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        /// @notice Address where fess are collected
        fees_collector: ContractAddress,
        /// @notice Upgradeable component storage
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        /// @notice ANVU exchange contract address
        avnu_exchange_address: ContractAddress,
        /// @notice STRK token contract address
        strk_token: ContractAddress,
        /// @notice ETH token contract address
        eth_token: ContractAddress,
    }

    /// @notice Contract events
    #[event]
    #[derive(starknet::Event, Drop)]
    enum Event {
        /// @notice Ownership-related events
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        /// @notice upgradeability-related events
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        /// @notice Event emitted upon a succesful token swap
        SwapSuccessful: SwapSuccessful,
        /// @notice Event emitted when a user subscribes to an asset
        Subscribed: Subscribed,
    }

    /// @notice Event emitted when a swap is successful
    #[derive(Drop, starknet::Event)]
    struct SwapSuccessful {
        /// @notice Address of the token being swapped from
        token_from_address: ContractAddress,
        /// @notice Amount of tokens being swapped from
        token_from_amount: u256,
        /// @notice Address of the token being swapped to
        token_to_address: ContractAddress,
        /// @notice Amount of tokens received in the swap
        token_to_amount: u256,
        /// @notice Address receiving the swapped tokens
        beneficiary: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    struct Subscribed {
        user: ContractAddress,
        assets: Assets,
    }

    /// @notice Initialize the contract with required addresses
    /// @param fees_collector Address where fees will be collected
    /// @param avnu_exchange_address Address of the AVNU exchange contract
    /// @param strk_token Address of the STRK token contract
    /// @param eth_token Address of the ETH token contract
    #[constructor]
    fn constructor(
        ref self: ContractState,
        fees_collector: ContractAddress,
        avnu_exchange_address: ContractAddress,
        strk_token: ContractAddress,
        eth_token: ContractAddress
    ) {
        /// @notice Initializes the owner as the caller
        self.ownable.initializer(get_caller_address());
        /// @notice Sets the fee collector address 
        self.fees_collector.write(fees_collector);
        /// @notice Stores the STRK token address
        self.strk_token.write(strk_token);
        /// @notice Stores the ETH token address
        self.eth_token.write(eth_token);
        /// @notice Sets the AVNU exchange address
        self.avnu_exchange_address.write(avnu_exchange_address);
    }

    /// @notice Implements upgrade-related functionality for the contract
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            /// @notice Ensures only owner can perform upgrades
            self.ownable.assert_only_owner();
            /// @notice Executes the upgrade logic
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    /// @notice Core AutoSwappr functionality including subscription and token swapping
    #[abi(embed_v0)]
    impl AutoSwappr of IAutoSwappr<ContractState> {
        /// @notice Subscribe to auto-swapping for specific assets
        /// @param assets Configuration of assets to enable for auto-swapping
        /// @dev Approves maximum allowance for specified tokens
        fn subscribe(ref self: ContractState, assets: Assets) {
            let caller = get_caller_address();
            assert(is_non_zero(caller), Errors::ZERO_ADDRESS_CALLER);

            /// @notice Define maximum u256 value for token approvals
            let max_u256 = u256 {
                low: 0xffffffffffffffffffffffffffffffff, high: 0xffffffffffffffffffffffffffffffff
            };

            /// @notice Approves STRK token if included in assets
            if assets.strk {
                let strk_token_address = self.strk_token.read();
                let strk_token = IERC20Dispatcher { contract_address: strk_token_address };
                strk_token.approve(get_contract_address(), max_u256);
            }

            /// @notice Approves ETH token if included in assets
            if assets.eth {
                let eth_token_address = self.eth_token.read();
                let eth_token = IERC20Dispatcher { contract_address: eth_token_address };
                eth_token.approve(get_contract_address(), max_u256);
            }

            /// @notice Emits the subscription event
            self.emit(Subscribed { user: caller, assets });
        }

        /// @notice Execute a token swap
        /// @param token_from_address Address of token to swap from
        /// @param token_from_amount Amount of tokens to swap
        /// @param token_to_address Address of token to swap to
        /// @param token_to_amount Expected amount of tokens to receive
        /// @param token_to_min_amount Minimum acceptable amount of tokens to receive
        /// @param beneficiary Address to receive the swapped tokens
        /// @param integrator_fee_amount_bps Fee amount in basis points
        /// @param integrator_fee_recipient Address to receive the fee
        /// @param routes Array of routes for the swap
        /// @dev Requires approval for token_from_address
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
            /// @notice Gets contract address
            let this_contract = get_contract_address();

            /// @notice Ensures the contract address is approved to spend the input token 
            assert(
                self.is_approved(this_contract, token_from_address), Errors::SPENDER_NOT_APPROVED
            );

            ///  @notice Performs swap using set internal logic
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

            /// @notice Ensures the swap was successful
            assert(swap, Errors::SWAP_FAILED);

            /// @notice Emits the successful swap event
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

    /// @dev Internal implementation trait
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// @notice Check if the contract is approved for a token
        /// @param beneficiary Address to check approval for
        /// @param token_contract Address of the token contract
        /// @return bool True if approved, false otherwise
        fn is_approved(
            self: @ContractState, beneficiary: ContractAddress, token_contract: ContractAddress
        ) -> bool {
            false
        }

        /// @notice Internal function to execute the swap
        /// @dev Calls AVNU exchange to perform the actual swap
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

        /// @notice Collect accumulated fees
        /// @dev Currently unimplemented
        fn collect_fees(ref self: ContractState) {}

        /// @notice Get the zero address constant
        /// @return ContractAddress The zero address
        fn zero_address(self: @ContractState) -> ContractAddress {
            contract_address_const::<0>()
        }
    }

    /// @notice Check if an address is non-zero
    /// @param address The address to check
    /// @return bool True if the address is non-zero, false otherwise
    fn is_non_zero(address: ContractAddress) -> bool {
        address.into() != 0
    }
}
