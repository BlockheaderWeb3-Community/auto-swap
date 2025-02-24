use starknet::ContractAddress;

#[starknet::interface]
pub trait IOperator<TContractState> {
    fn set_operator(ref self: TContractState, address: ContractAddress);
    fn remove_operator(ref self: TContractState, address: ContractAddress);
    fn is_operator(self: @TContractState, address: ContractAddress) -> bool;
}

