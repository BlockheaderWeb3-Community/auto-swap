pub mod Errors {
    pub const ZERO_ADDRESS: felt252 = 'Address cannot be zero';
    pub const NOT_OWNER: felt252 = 'Caller Not Owner';
    pub const SWAP_FAILED: felt252 = 'Swap Failed';
    pub const INVALID_TOKEN_SELECTION: felt252 = 'Cannot Select Same Token';
    pub const FROM_TOKEN_ZERO_VALUE: felt252 = 'Cannot Swap From Zero';
    pub const TO_TOKEN_ZERO_VALUE: felt252 = 'Cannot Swap to Zero';
    pub const ZERO_ADDRESS_BENEFICIARY: felt252 = 'Beneficiary cannot be zero addr';
    pub const INSUFFICIENT_BALANCE: felt252 = 'Insufficient Balance';
    pub const TRANSFER_FAILED: felt252 = 'Transfer Failed';
    pub const SPENDER_NOT_APPROVED: felt252 = 'Spender not approved';
    pub const INVALID_TOKEN_CONTRACT: felt252 = 'Invalid token contract address';
    pub const ZERO_ALLOWANCE: felt252 = 'Allowance is zero';
    pub const EXTERNAL_CONTRACT_CALL_FAILED: felt252 = 'External interaction failed';
    pub const UNSUPPORTED_TOKEN: felt252 = 'Token type not supported';
    pub const APPROVAL_EXCEEDED: felt252 = 'Amount exceeds allowed limit';
}
