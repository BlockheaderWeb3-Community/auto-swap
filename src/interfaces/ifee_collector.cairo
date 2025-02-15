use starknet::ContractAddress;

#[starknet::interface]
pub trait IFeeCollector<TContractState> {
    fn withdraw(ref self: TContractState, address: ContractAddress, amount: u256, token: felt252);
    fn get_token_balance(self: @TContractState, token: felt252) -> u256;
}

