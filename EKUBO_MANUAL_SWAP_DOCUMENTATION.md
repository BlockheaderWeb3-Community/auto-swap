# Ekubo Manual Swap Documentation

## Overview

The `ekubo_manual_swap` function allows users to perform token swaps directly on Ekubo pools through the AutoSwappr contract. Unlike the `ekubo_swap` function, this function doesn't require operator permissions and can be called by any user who has approved the contract to spend their tokens.

## Function Signature

```typescript
ekubo_manual_swap(swap_data: SwapData): Promise<SwapResult>
```

## Prerequisites

1. **Starknet.js Setup**: Ensure you have Starknet.js installed and configured
2. **Account Setup**: A Starknet account with sufficient token balance
3. **Token Approval**: The user must approve the AutoSwappr contract to spend their tokens
4. **Supported Tokens**: The input token must be supported by the contract

## Required Types

### SwapData Structure

```typescript
interface SwapData {
  params: SwapParameters;
  pool_key: PoolKey;
  caller: ContractAddress;
}
```

### SwapParameters Structure

```typescript
interface SwapParameters {
  amount: i129; // Amount to swap with magnitude and sign
  sqrt_ratio_limit: u128; // Price limit for the swap
  is_token1: boolean; // Whether the input token is token1
  skip_ahead: u32; // Skip ahead parameter
}
```

### PoolKey Structure

```typescript
interface PoolKey {
  token0: ContractAddress; // First token in the pool
  token1: ContractAddress; // Second token in the pool
  fee: u128; // Pool fee in basis points
  tick_spacing: u32; // Tick spacing for the pool
  extension: felt252; // Pool extension parameter
}
```

### SwapResult Structure

```typescript
interface SwapResult {
  delta: Delta; // Contains the swap results
}
```

### i129 Structure (Ekubo Amount)

```typescript
interface i129 {
  mag: u128; // Magnitude of the amount
  sign: boolean; // Sign (false = positive, true = negative)
}
```

## Step-by-Step Implementation

### 1. Install Dependencies

```bash
npm install starknet
```

### 2. Setup Starknet.js

```typescript
import { Account, Contract, RpcProvider, uint256, cairo } from "starknet";

// Initialize provider
const provider = new RpcProvider({
  nodeUrl: "https://starknet-mainnet.public.blastapi.io"
});

// Initialize account
const account = new Account(
  provider,
  "0xYOUR_ACCOUNT_ADDRESS",
  "0xYOUR_PRIVATE_KEY"
);
```

### 3. Contract Setup

```typescript
// AutoSwappr contract address
const AUTOSWAPPR_ADDRESS = '0xYOUR_AUTOSWAPPR_CONTRACT_ADDRESS';

// Contract ABI (you'll need to generate this from your Cairo contract)
const autoswapprAbi = [...]; // Your contract ABI

// Initialize contract
const autoswapprContract = new Contract(
  autoswapprAbi,
  AUTOSWAPPR_ADDRESS,
  account
);
```

### 4. Token Approval

Before calling the swap function, you must approve the AutoSwappr contract to spend your tokens:

```typescript
// Token contract address (e.g., STRK token)
const TOKEN_ADDRESS = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';

// Token ABI
const tokenAbi = [...]; // ERC20 ABI

// Initialize token contract
const tokenContract = new Contract(tokenAbi, TOKEN_ADDRESS, account);

// Approve the AutoSwappr contract to spend tokens
const approveAmount = uint256.bnToUint256('1000000000000000000'); // 1 token with 18 decimals

const approveResult = await tokenContract.approve(
  AUTOSWAPPR_ADDRESS,
  approveAmount
);

console.log('Approval transaction hash:', approveResult.transaction_hash);
```

### 5. Prepare Swap Data

```typescript
// Example: Swap STRK for USDC
const createSwapData = () => {
  // Pool key for STRK/USDC pool
  const poolKey = {
    token0:
      "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d", // STRK
    token1:
      "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8", // USDC
    fee: "170141183460469235273462165868118016",
    tick_spacing: 1000,
    extension: "0"
  };

  // Swap parameters
  const swapParams = {
    amount: {
      mag: "1000000000000000000", // 1 STRK (18 decimals)
      sign: false // positive amount
    },
    sqrt_ratio_limit: "18446748437148339061", // min sqrt ratio limit
    is_token1: false, // STRK is token0 in this pool
    skip_ahead: 0
  };

  // Swap data
  const swapData = {
    params: swapParams,
    pool_key: poolKey,
    caller: account.address // Your account address
  };

  return swapData;
};
```

### 6. Execute the Swap

```typescript
const executeEkuboManualSwap = async () => {
  try {
    const swapData = createSwapData();

    console.log("Executing Ekubo manual swap...");
    console.log("Swap data:", JSON.stringify(swapData, null, 2));

    // Call the ekubo_manual_swap function
    const result = await autoswapprContract.ekubo_manual_swap(swapData);

    console.log("Swap successful!");
    console.log("Transaction hash:", result.transaction_hash);
    console.log("Swap result:", result);

    return result;
  } catch (error) {
    console.error("Swap failed:", error);
    throw error;
  }
};

// Execute the swap
executeEkuboManualSwap();
```

## Complete Example

```typescript
import { Account, Contract, RpcProvider, uint256, cairo } from "starknet";

class EkuboManualSwap {
  private provider: RpcProvider;
  private account: Account;
  private autoswapprContract: Contract;
  private tokenContract: Contract;

  constructor(
    accountAddress: string,
    privateKey: string,
    autoswapprAddress: string,
    tokenAddress: string
  ) {
    this.provider = new RpcProvider({
      nodeUrl: "https://starknet-mainnet.public.blastapi.io"
    });

    this.account = new Account(this.provider, accountAddress, privateKey);

    this.autoswapprContract = new Contract(
      autoswapprAbi, // Your contract ABI
      autoswapprAddress,
      this.account
    );

    this.tokenContract = new Contract(
      tokenAbi, // ERC20 ABI
      tokenAddress,
      this.account
    );
  }

  async approveTokens(amount: string) {
    const approveAmount = uint256.bnToUint256(amount);

    const result = await this.tokenContract.approve(
      this.autoswapprContract.address,
      approveAmount
    );

    console.log("Approval transaction hash:", result.transaction_hash);
    return result;
  }

  async executeSwap(
    token0Address: string,
    token1Address: string,
    amount: string,
    isToken1: boolean = false
  ) {
    // Create swap data
    const swapData = {
      params: {
        amount: {
          mag: amount,
          sign: false
        },
        sqrt_ratio_limit: "18446748437148339061",
        is_token1: isToken1,
        skip_ahead: 0
      },
      pool_key: {
        token0: token0Address,
        token1: token1Address,
        fee: "170141183460469235273462165868118016",
        tick_spacing: 1000,
        extension: "0"
      },
      caller: this.account.address
    };

    console.log("Executing swap with data:", JSON.stringify(swapData, null, 2));

    const result = await this.autoswapprContract.ekubo_manual_swap(swapData);

    console.log("Swap successful! Transaction hash:", result.transaction_hash);
    return result;
  }
}

// Usage example
const swap = new EkuboManualSwap(
  "0xYOUR_ACCOUNT_ADDRESS",
  "0xYOUR_PRIVATE_KEY",
  "0xYOUR_AUTOSWAPPR_CONTRACT_ADDRESS",
  "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d" // STRK token
);

// First approve tokens
await swap.approveTokens("1000000000000000000"); // 1 STRK

// Then execute the swap
await swap.executeSwap(
  "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d", // STRK
  "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8", // USDC
  "1000000000000000000", // 1 STRK
  false // STRK is token0
);
```

## Important Notes

### 1. Pool Configuration

- Different token pairs have different pool configurations
- The `fee`, `tick_spacing`, and `extension` values are specific to each pool
- Ensure you're using the correct pool key for your token pair

### 2. Token Order

- The `is_token1` parameter determines which token is being swapped
- `false` means the input token is `token0`
- `true` means the input token is `token1`

### 3. Amount Format

- Amounts must be provided as strings representing the raw token amount
- Include all decimal places (e.g., 1 STRK = '1000000000000000000' with 18 decimals)

### 4. Error Handling

Common errors and their causes:

- `INSUFFICIENT_ALLOWANCE`: Token approval is insufficient
- `UNSUPPORTED_TOKEN`: Input token is not supported by the contract
- `ZERO_AMOUNT`: Swap amount is zero
- `u256_sub Overflow`: Insufficient token balance

### 5. Gas Estimation

Always estimate gas before executing transactions:

```typescript
const estimatedGas = await autoswapprContract.ekubo_manual_swap.estimateGas(
  swapData
);
console.log("Estimated gas:", estimatedGas);
```

### 6. Event Listening

Listen for the `SwapSuccessful` event to confirm the swap:

```typescript
autoswapprContract.on("SwapSuccessful", (event) => {
  console.log("Swap successful event:", event);
  console.log("Token from:", event.token_from_address);
  console.log("Token to:", event.token_to_address);
  console.log("Amount received:", event.token_to_amount);
});
```

## Supported Token Pairs

Based on the contract implementation, the following token pairs are supported:

- STRK/USDC
- STRK/USDT
- ETH/USDC
- ETH/USDT

## Fee Structure

The contract applies fees on the output tokens:

- **Fixed Fee**: A fixed amount in basis points (e.g., 50 = 0.5$ fee)
- **Percentage Fee**: A percentage of the output amount (e.g., 100 = 1%)

Fees are automatically deducted from the received tokens and sent to the fee collector address.

## Security Considerations

1. **Private Key Management**: Never expose private keys in client-side code
2. **Token Approvals**: Only approve the amount you intend to swap
3. **Slippage Protection**: Consider implementing slippage checks
4. **Pool Validation**: Verify pool addresses and parameters before swapping
5. **Error Handling**: Implement proper error handling for failed transactions

## Testing

Before deploying to mainnet, test your implementation on testnet:

```typescript
// Use testnet provider
const provider = new RpcProvider({
  nodeUrl: "https://starknet-goerli.public.blastapi.io"
});
```

This documentation provides a comprehensive guide for integrating the `ekubo_manual_swap` function into your Starknet.js application. Always test thoroughly and ensure proper error handling in production environments.
