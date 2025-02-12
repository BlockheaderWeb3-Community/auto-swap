#[starknet::contract]
pub mod FeeCollector {
    // starknet imports
    use starknet::{ContractAddress, get_contract_address, ClassHash};

    // OZ imports
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    // Package imports
    use crate::interfaces::ifee_collector::IFeeCollector;
    use crate::base::types::{Token};
    use crate::base::errors::Errors;
    use crate::components::operator::OperatorComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OperatorComponent, storage: operator, event: OperatorEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OperatorImpl = OperatorComponent::OperatorComponent<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        operator: OperatorComponent::Storage,
        strk_contract_address: ContractAddress,
        usdt_contract_address: ContractAddress,
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
        ERC20Event: ERC20Component::Event,
        #[flat]
        OperatorEvent: OperatorComponent::Event,
        FeesWithdrawn: FeesWithdrawn
    }

    // @notice Event emitted when fees is successfully withdrawn
    // @param address Address the fee was withdrawn to
    // @param amount Amount of fees withdrawn
    #[derive(Drop, starknet::Event)]
    pub struct FeesWithdrawn {
        address: ContractAddress,
        amount: u256
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
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    impl FeeCollectorImpl of IFeeCollector<ContractState> {
        fn withdraw(ref self: ContractState, address: ContractAddress, amount: u256, token: Token) {
            self.ownable.assert_only_owner();
            assert(self.operator.is_operator(address), Errors::NOT_OPERATOR);

            let token_contract_dispactcher: ERC20ABIDispatcher = match token {
                Token::STRK => {
                    ERC20ABIDispatcher { contract_address: self.strk_contract_address.read() }
                },
                Token::USDT => {
                    ERC20ABIDispatcher { contract_address: self.usdt_contract_address.read() }
                }
            };

            let contract_balance: u256 = token_contract_dispactcher
                .balance_of(get_contract_address());
            assert(contract_balance > amount, Errors::INSUFFICIENT_BALANCE);

            token_contract_dispactcher.transfer(address, amount);

            self.emit(FeesWithdrawn { address, amount })
        }

        fn get_token_balance(self: @ContractState, token: Token) -> u256 {
            let token_contract_dispactcher: ERC20ABIDispatcher = match token {
                Token::STRK => {
                    ERC20ABIDispatcher { contract_address: self.strk_contract_address.read() }
                },
                Token::USDT => {
                    ERC20ABIDispatcher { contract_address: self.usdt_contract_address.read() }
                }
            };

            token_contract_dispactcher.balance_of(get_contract_address())
        }
    }
}
