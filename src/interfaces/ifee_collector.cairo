use starknet::ContractAddress;
use crate::base::types::{Token};

#[starknet::interface]
pub trait IFeeCollector<TContractState> {
    fn withdraw(ref self: TContractState, address: ContractAddress, amount: u256, token: Token);
    fn get_token_balance(self: @TContractState, token: Token) -> u256;
}

