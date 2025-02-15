#[starknet::contract]
pub mod FeeCollector {
    // starknet imports
    use starknet::{ContractAddress, get_contract_address, ClassHash, get_block_timestamp};
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess};

    // OZ imports
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // Package imports
    use crate::interfaces::ifee_collector::IFeeCollector;
    use crate::base::types::{Token};
    use crate::base::errors::Errors;
    use crate::components::operator::OperatorComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OperatorComponent, storage: operator, event: OperatorEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OperatorImpl = OperatorComponent::OperatorComponent<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        operator: OperatorComponent::Storage,
        strk_contract_address: ContractAddress,
        usdt_contract_address: ContractAddress,
        token_type: Map<felt252, Token>
    }

    // @notice Events emitted by the contract
    #[event]
    #[derive(starknet::Event, Drop)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OperatorEvent: OperatorComponent::Event,
        FeesWithdrawn: FeesWithdrawn
    }

    // @notice Event emitted when fees is successfully withdrawn
    // @param address Address the fee was withdrawn to
    // @param amount Amount of fees withdrawn
    #[derive(Drop, starknet::Event)]
    pub struct FeesWithdrawn {
        pub address: ContractAddress,
        pub amount: u256,
        pub timestamp: u64
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        strk_contract_address: ContractAddress,
        usdt_contract_address: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.strk_contract_address.write(strk_contract_address);
        self.usdt_contract_address.write(usdt_contract_address);

        self.token_type.write('STRK', Token::STRK);
        self.token_type.write('USDT', Token::USDT);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl FeeCollectorImpl of IFeeCollector<ContractState> {
        fn withdraw(
            ref self: ContractState, address: ContractAddress, amount: u256, token: felt252
        ) {
            self.ownable.assert_only_owner();
            assert(self.operator.is_operator(address), Errors::NOT_OPERATOR);

            let token_type = self.token_type.read(token);

            let token_contract_dispactcher: IERC20Dispatcher = match token_type {
                Token::STRK => {
                    IERC20Dispatcher { contract_address: self.strk_contract_address.read() }
                },
                Token::USDT => {
                    IERC20Dispatcher { contract_address: self.usdt_contract_address.read() }
                }
            };

            let contract_balance: u256 = token_contract_dispactcher
                .balance_of(get_contract_address());

            assert(contract_balance > amount, Errors::INSUFFICIENT_BALANCE);

            token_contract_dispactcher.transfer(address, amount);

            self.emit(FeesWithdrawn { address, amount, timestamp: get_block_timestamp() })
        }

        fn get_token_balance(self: @ContractState, token: felt252) -> u256 {
            let token_type = self.token_type.read(token);

            let token_contract_dispactcher: IERC20Dispatcher = match token_type {
                Token::STRK => {
                    IERC20Dispatcher { contract_address: self.strk_contract_address.read() }
                },
                Token::USDT => {
                    IERC20Dispatcher { contract_address: self.usdt_contract_address.read() }
                }
            };

            token_contract_dispactcher.balance_of(get_contract_address())
        }
    }
}
