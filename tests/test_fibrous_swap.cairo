// *************************************************************************
//                              FIBROUS SWAP TEST
// *************************************************************************
use core::result::ResultTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait,
    start_cheat_account_contract_address,
    stop_cheat_account_contract_address,
};

use auto_swappr::interfaces::iautoswappr::{IAutoSwapprDispatcher, IAutoSwapprDispatcherTrait};
use auto_swappr::base::types::{RouteParams, SwapParams};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

const OWNER: felt252 = 'OWNER';
const FEE_COLLECTOR: felt252 = 0x0114B0b4A160bCC34320835aEFe7f01A2a3885e4340Be0Bc1A63194469984a06;

fn AVNU_EXCHANGE_ADDRESS () -> ContractAddress {
    contract_address_const::<0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f>()
}
fn FIBROUS_EXCHANGE_ADDRESS () -> ContractAddress {
    contract_address_const::<0x00f6f4CF62E3C010E0aC2451cC7807b5eEc19a40b0FaaCd00CCA3914280FDf5a>()
}

fn STRK_TOKEN_ADDRESS () -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

fn ETH_TOKEN_ADDRESS () -> ContractAddress {
    contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
}

fn USDC_TOKEN_ADDRESS () -> ContractAddress {
    contract_address_const::<0x053C91253BC9682c04929cA02ED00b3E423f6710D2ee7e0D5EBB06F3eCF368A8>()
}

fn USDT_TOKEN_ADDRESS () -> ContractAddress {
    contract_address_const::<0x068F5c6a61780768455de69077E07e89787839bf8166dEcfBf92B645209c0fB8>()
}

fn ADDRESS_WITH_STRK_1 () -> ContractAddress {
    contract_address_const::<0x0298a9d0d82aabfd7e2463bb5ec3590c4e86d03b2ece868d06bbe43475f2d3e6>()
}

fn ADDRESS_WITH_ETH_1 () -> ContractAddress {
    // 0.010608430645451531 ETH = 42.449317USD on block 
    contract_address_const::<0x028096b9a1b0f085ed2a6e6c07a58c2a33a0789c6a9d0ff55b0f816d52ab948e>()
}

fn JEDISWAP_POOL_ADDRESS () -> ContractAddress {
    contract_address_const::<0x5726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26>()
} 

fn STRK_TOKEN () -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() }
}

fn ETH_TOKEN () -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() }
}

fn USDT_TOKEN () -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() }
}

fn USDC_TOKEN () -> IERC20Dispatcher {
    IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() }
} 

const AMOUNT_TO_SWAP_STRK: u256 = 1000000000000000000;
const AMOUNT_TO_SWAP_ETH: u256 = 10000000000000000;
const MIN_RECEIVED_STRK_TO_STABLE: u256 = 610000;
const MIN_RECEIVED_ETH_TO_STABLE: u256 = 38000000;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> IAutoSwapprDispatcher {
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut auto_swappr_constructor_calldata: Array<felt252> = array![
        FEE_COLLECTOR, AVNU_EXCHANGE_ADDRESS().into(), FIBROUS_EXCHANGE_ADDRESS().into(), STRK_TOKEN_ADDRESS().into(), ETH_TOKEN_ADDRESS().into(), OWNER,
    ];

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@auto_swappr_constructor_calldata)
        .unwrap();

    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: auto_swappr_contract_address,
    };
    autoSwappr_dispatcher
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
fn test_fibrous_swap_strk_to_usdt() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();
    
    // variables for test
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    let strk_amount_before_swap = STRK_TOKEN().balance_of(ADDRESS_WITH_STRK_1());
    let usdt_amount_before_swap = USDT_TOKEN().balance_of(ADDRESS_WITH_STRK_1());
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    stop_cheat_caller_address(USDT_TOKEN().contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_STRK);
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_STRK
    );
    stop_cheat_caller_address(STRK_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_STRK_1()
    };

    let swapParamsItem = SwapParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(),
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_STRK_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    assert_eq!(STRK_TOKEN().balance_of(ADDRESS_WITH_STRK_1()), strk_amount_before_swap - AMOUNT_TO_SWAP_STRK, "Balance of from token should decrease");
    assert_ge!(USDT_TOKEN().balance_of(ADDRESS_WITH_STRK_1()), usdt_amount_before_swap + MIN_RECEIVED_STRK_TO_STABLE, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
fn test_fibrous_swap_strk_to_usdc() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();
        
    // variables for test
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    let strk_amount_before_swap = STRK_TOKEN().balance_of(ADDRESS_WITH_STRK_1());
    let usdc_amount_before_swap = USDC_TOKEN().balance_of(ADDRESS_WITH_STRK_1());
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    stop_cheat_caller_address(USDC_TOKEN().contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_STRK);
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_STRK
    );
    stop_cheat_caller_address(STRK_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_STRK_1()
    };

    let swapParamsItem = SwapParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_STRK_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    assert_eq!(STRK_TOKEN().balance_of(ADDRESS_WITH_STRK_1()), strk_amount_before_swap - AMOUNT_TO_SWAP_STRK, "Balance of from token should decrease");
    assert_ge!(USDC_TOKEN().balance_of(ADDRESS_WITH_STRK_1()), usdc_amount_before_swap + MIN_RECEIVED_STRK_TO_STABLE, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 990337)]
fn test_fibrous_swap_eth_to_usdt() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();
    
    // variables for test
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    let eth_amount_before_swap = ETH_TOKEN().balance_of(ADDRESS_WITH_ETH_1());
    let usdt_amount_before_swap = USDT_TOKEN().balance_of(ADDRESS_WITH_ETH_1());
    stop_cheat_caller_address(ETH_TOKEN().contract_address);
    stop_cheat_caller_address(USDT_TOKEN().contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    ETH_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_ETH);
    stop_cheat_caller_address(ETH_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    ETH_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_ETH
    );
    stop_cheat_caller_address(ETH_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_ETH,
        min_received: MIN_RECEIVED_ETH_TO_STABLE,
        destination: ADDRESS_WITH_ETH_1()
    };

    let swapParamsItem = SwapParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_ETH_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_caller_address(USDT_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    assert_eq!(ETH_TOKEN().balance_of(ADDRESS_WITH_ETH_1()), eth_amount_before_swap - AMOUNT_TO_SWAP_ETH, "Balance of from token should decrease");
    assert_ge!(USDT_TOKEN().balance_of(ADDRESS_WITH_ETH_1()), usdt_amount_before_swap + MIN_RECEIVED_ETH_TO_STABLE, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 990337)]
fn test_fibrous_swap_eth_to_usdc() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();

    // variables for test
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    let eth_amount_before_swap = ETH_TOKEN().balance_of(ADDRESS_WITH_ETH_1());
    let usdc_amount_before_swap = USDC_TOKEN().balance_of(ADDRESS_WITH_ETH_1());
    stop_cheat_caller_address(ETH_TOKEN().contract_address);
    stop_cheat_caller_address(USDC_TOKEN().contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    ETH_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_ETH);
    stop_cheat_caller_address(ETH_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    ETH_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_ETH
    );
    stop_cheat_caller_address(ETH_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_ETH,
        min_received: MIN_RECEIVED_ETH_TO_STABLE,
        destination: ADDRESS_WITH_ETH_1()
    };

    let swapParamsItem = SwapParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_ETH_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(ETH_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    start_cheat_caller_address(USDC_TOKEN().contract_address, ADDRESS_WITH_ETH_1());
    assert_eq!(ETH_TOKEN().balance_of(ADDRESS_WITH_ETH_1()), eth_amount_before_swap - AMOUNT_TO_SWAP_ETH, "Balance of from token should decrease");
    assert_ge!(USDC_TOKEN().balance_of(ADDRESS_WITH_ETH_1()), usdc_amount_before_swap + MIN_RECEIVED_ETH_TO_STABLE, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_fibrous_swap_should_fail_for_insufficient_allowance_to_contract() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_STRK - 1000); // subtracting to provocate allowance error
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_STRK
    );
    stop_cheat_caller_address(STRK_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_STRK_1()
    };

    let swapParamsItem = SwapParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_STRK_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
#[should_panic(expected: 'Token not supported')]
fn test_fibrous_swap_should_fail_for_token_not_supported() {
    // Deploying auto swapper contract 
    let autoSwappr_dispatcher = __setup__();

    let unsupported_token = contract_address_const::<0x123>();
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN().approve(autoSwappr_dispatcher.contract_address, AMOUNT_TO_SWAP_STRK - 1000); // subtracting to provocate allowance error
    stop_cheat_caller_address(STRK_TOKEN().contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(STRK_TOKEN().contract_address, ADDRESS_WITH_STRK_1());
    STRK_TOKEN()
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        AMOUNT_TO_SWAP_STRK
    );
    stop_cheat_caller_address(STRK_TOKEN().contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: AMOUNT_TO_SWAP_STRK,
        min_received: MIN_RECEIVED_STRK_TO_STABLE,
        destination: ADDRESS_WITH_STRK_1()
    };

    let swapParamsItem = SwapParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        pool_address: JEDISWAP_POOL_ADDRESS(), 
        rate: 1000000,
        protocol_id: 2,
        extra_data: array![],
    };
    let swapParams = array![swapParamsItem];


    // Calling function
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, ADDRESS_WITH_STRK_1());
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), ADDRESS_WITH_STRK_1());
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
}