#[starknet::component]
pub mod OperatorComponent {
    use starknet::{ContractAddress, get_block_timestamp};
    use starknet::storage::{Map};

    use openzeppelin_access::ownable::{
        OwnableComponent, OwnableComponent::InternalImpl as OwnableInternalImpl
    };

    use crate::interfaces::ioperator::{IOperator};
    use crate::base::errors::Errors;

    #[storage]
    pub struct Storage {
        operator_addresses: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OperatorAdded: OperatorAdded,
        OperatorRemoved: OperatorRemoved
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct OperatorAdded {
        pub operator: ContractAddress,
        pub time_added: u64
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct OperatorRemoved {
        pub operator: ContractAddress,
        pub time_removed: u64
    }

    #[embeddable_as(OperatorComponent)]
    impl OperatorComponentImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
    > of IOperator<ComponentState<TContractState>> {
        fn set_operator(ref self: ComponentState<TContractState>, address: ContractAddress) {
            // Assert only owner
            let ownable_comp = get_dep_component!(@self, Ownable);
            ownable_comp.assert_only_owner();

            // Check if operator doesn't already exist
            assert(!self.operator_addresses.read(address), Errors::EXISTING_ADDRESS);

            // Add operator
            self.operator_addresses.write(address, true);

            // Emit event
            self
                .emit(
                    OperatorAdded { operator: address, time_added: get_block_timestamp().into() }
                );
        }

        fn remove_operator(ref self: ComponentState<TContractState>, address: ContractAddress) {
            // Assert only owner
            let ownable_comp = get_dep_component!(@self, Ownable);
            ownable_comp.assert_only_owner();

            // Check if operator exists
            assert(self.operator_addresses.read(address), Errors::NON_EXISTING_ADDRESS);

            // Remove operator
            self.operator_addresses.write(address, false);

            // Emit event
            self
                .emit(
                    OperatorRemoved {
                        operator: address, time_removed: get_block_timestamp().into()
                    }
                );
        }

        fn is_operator(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            self.operator_addresses.read(address)
        }
    }
}
