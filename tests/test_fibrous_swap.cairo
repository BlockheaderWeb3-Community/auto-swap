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


// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    let auto_swappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut auto_swappr_constructor_calldata: Array<felt252> = array![
        FEE_COLLECTOR, AVNU_EXCHANGE_ADDRESS().into(), FIBROUS_EXCHANGE_ADDRESS().into(), STRK_TOKEN_ADDRESS().into(), ETH_TOKEN_ADDRESS().into(), OWNER,
    ];

    let (auto_swappr_contract_address, _) = auto_swappr_class_hash
        .deploy(@auto_swappr_constructor_calldata)
        .unwrap();

    auto_swappr_contract_address
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
fn test_fibrous_swap_strk_to_usdt() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_STRK_1();
    let amount_to_swap = 1000000000000000000; // 1 STRK
    let strk_token = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };
    let usdt_token = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let min_received = 610000;
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdt_token.contract_address, address_with_funds);
    let strk_amount_before_swap = strk_token.balance_of(address_with_funds);
    let usdt_amount_before_swap = usdt_token.balance_of(address_with_funds);
    stop_cheat_caller_address(strk_token.contract_address);
    stop_cheat_caller_address(usdt_token.contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap);
    stop_cheat_caller_address(strk_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(strk_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdt_token.contract_address, address_with_funds);
    assert_eq!(strk_token.balance_of(address_with_funds), strk_amount_before_swap - amount_to_swap, "Balance of from token should decrease");
    assert_ge!(usdt_token.balance_of(address_with_funds), usdt_amount_before_swap + min_received, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
fn test_fibrous_swap_strk_to_usdc() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_STRK_1();
    let amount_to_swap = 1000000000000000000; // 1 STRK
    let strk_token = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };
    let usdc_token = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
    let min_received = 610000;
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdc_token.contract_address, address_with_funds);
    let strk_amount_before_swap = strk_token.balance_of(address_with_funds);
    let usdc_amount_before_swap = usdc_token.balance_of(address_with_funds);
    stop_cheat_caller_address(strk_token.contract_address);
    stop_cheat_caller_address(usdc_token.contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap);
    stop_cheat_caller_address(strk_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(strk_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdc_token.contract_address, address_with_funds);
    assert_eq!(strk_token.balance_of(address_with_funds), strk_amount_before_swap - amount_to_swap, "Balance of from token should decrease");
    assert_ge!(usdc_token.balance_of(address_with_funds), usdc_amount_before_swap + min_received, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 990337)]
fn test_fibrous_swap_eth_to_usdt() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_ETH_1();
    let amount_to_swap = 10000000000000000; // 0.01 ETH (40$) 
    let eth_token = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };
    let usdt_token = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let min_received = 38000000; // 38$
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdt_token.contract_address, address_with_funds);
    let strk_amount_before_swap = eth_token.balance_of(address_with_funds);
    let usdt_amount_before_swap = usdt_token.balance_of(address_with_funds);
    stop_cheat_caller_address(eth_token.contract_address);
    stop_cheat_caller_address(usdt_token.contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    eth_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap);
    stop_cheat_caller_address(eth_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    eth_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(eth_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdt_token.contract_address, address_with_funds);
    assert_eq!(eth_token.balance_of(address_with_funds), strk_amount_before_swap - amount_to_swap, "Balance of from token should decrease");
    assert_ge!(usdt_token.balance_of(address_with_funds), usdt_amount_before_swap + min_received, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 990337)]
fn test_fibrous_swap_eth_to_usdc() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_ETH_1();
    let amount_to_swap = 10000000000000000; // 0.01 ETH (40$) 
    let eth_token = IERC20Dispatcher { contract_address: ETH_TOKEN_ADDRESS() };
    let usdc_token = IERC20Dispatcher { contract_address: USDC_TOKEN_ADDRESS() };
    let min_received = 38000000; // 38$
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdc_token.contract_address, address_with_funds);
    let strk_amount_before_swap = eth_token.balance_of(address_with_funds);
    let usdc_amount_before_swap = usdc_token.balance_of(address_with_funds);
    stop_cheat_caller_address(eth_token.contract_address);
    stop_cheat_caller_address(usdc_token.contract_address);
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    eth_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap);
    stop_cheat_caller_address(eth_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    eth_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(eth_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: ETH_TOKEN_ADDRESS(),
        token_out: USDC_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
    stop_cheat_caller_address(autoSwappr_dispatcher.contract_address);
    stop_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS());

    // asserts
    start_cheat_caller_address(eth_token.contract_address, address_with_funds);
    start_cheat_caller_address(usdc_token.contract_address, address_with_funds);
    assert_eq!(eth_token.balance_of(address_with_funds), strk_amount_before_swap - amount_to_swap, "Balance of from token should decrease");
    assert_ge!(usdc_token.balance_of(address_with_funds), usdc_amount_before_swap + min_received, "Balance of to token should increase");
}

#[test]
#[fork(url: "https://starknet-mainnet.public.blastapi.io/rpc/v0_7", block_number: 987853)]
#[should_panic(expected: 'Insufficient Allowance')]
fn test_fibrous_swap_should_fail_for_insufficient_allowance_to_contract() {
    // Deploying auto swapper contract 
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_STRK_1();
    let amount_to_swap = 1000000000000000000; // 1 STRK
    let strk_token = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };
    let usdt_token = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let min_received = 610000;
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap - 1000); // subtracting to provocate allowance error
    stop_cheat_caller_address(strk_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(strk_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: STRK_TOKEN_ADDRESS(),
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
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
    let autoSwappr_contract_address = __setup__();
    let autoSwappr_dispatcher = IAutoSwapprDispatcher {
        contract_address: autoSwappr_contract_address.clone(),
    };
    
    // variables used on all test 
    let address_with_funds = ADDRESS_WITH_STRK_1();
    let amount_to_swap = 1000000000000000000; // 1 STRK
    let strk_token = IERC20Dispatcher { contract_address: STRK_TOKEN_ADDRESS() };
    let usdt_token = IERC20Dispatcher { contract_address: USDT_TOKEN_ADDRESS() };
    let min_received = 610000;

    let unsupported_token = contract_address_const::<0x123>();
    
    // approving auto swapper to use the amount to swap. (such contract will use transfer_from before call fibrous swaper) 
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token.approve(autoSwappr_dispatcher.contract_address, amount_to_swap - 1000); // subtracting to provocate allowance error
    stop_cheat_caller_address(strk_token.contract_address);
    
    // Approve Fibrous exchange contract to use to amount we want to swap
    start_cheat_caller_address(strk_token.contract_address, address_with_funds);
    strk_token
    .approve(
        FIBROUS_EXCHANGE_ADDRESS(), // fibrous
        amount_to_swap
    );
    stop_cheat_caller_address(strk_token.contract_address);

    // Preparing params to call auto swapper's fibrous_swap function
    let routeParams = RouteParams {
        token_in: unsupported_token,
        token_out: USDT_TOKEN_ADDRESS(),
        amount_in: amount_to_swap,
        min_received: min_received,
        destination: address_with_funds
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
    start_cheat_caller_address(autoSwappr_dispatcher.contract_address, address_with_funds);
    start_cheat_account_contract_address(FIBROUS_EXCHANGE_ADDRESS(), address_with_funds);
    autoSwappr_dispatcher
        .fibrous_swap(
            routeParams,
            swapParams,
        );
}