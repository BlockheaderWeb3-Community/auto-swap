pub mod Errors {
    pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be zero addr';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be zero addr';
    pub const NOT_OWNER: felt252 = 'Caller Not Owner';
    pub const SWAP_FAILED: felt252 = 'Swap Failed';
    pub const INVALID_TOKEN_SELECTION: felt252 = 'Cannot Select Same Token';
    pub const FROM_TOKEN_ZERO_VALUE: felt252 = 'Cannot Swap From Zero';
    pub const TO_TOKEN_ZERO_VALUE: felt252 = 'Cannot Swap to Zero';
    pub const ZERO_ADDRESS_BENEFICIARY: felt252 = 'Beneficiary cannot be zero addr';
}
