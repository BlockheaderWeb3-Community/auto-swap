// *************************************************************************
//                              Events TEST
// *************************************************************************
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, ClassHash};

use snforge_std::{
    declare, start_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait
};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher};
use openzeppelin::upgrades::interface::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};

const USER: felt252 = 'USER';
const AVNU_ADDR: felt252 = 'AVNU';
const FEE_COLLECTOR_ADDR: felt252 = 'FEE_COLLECTOR';
const OWNER: felt252 = 'OWNER';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, IERC20Dispatcher, IERC20Dispatcher) {
    let STRK: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let ETH: ContractAddress = 0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();

    let strk_dispatcher = IERC20Dispatcher { contract_address: STRK };
    let eth_dispatcher = IERC20Dispatcher { contract_address: ETH };

    let STRK_FELT: felt252 = STRK.into();
    let ETH_FELT: felt252 = ETH.into();

    let autoSwappr_class_hash = declare("AutoSwappr").unwrap().contract_class();

    let mut autoSwappr_constructor_calldata: Array<felt252> = array![
        OWNER, AVNU_ADDR, STRK_FELT, ETH_FELT
    ];
    let (autoSwappr_contract_address, _) = autoSwappr_class_hash
        .deploy(@autoSwappr_constructor_calldata)
        .unwrap();

    return (autoSwappr_contract_address, strk_dispatcher, eth_dispatcher);
}

#[test]
#[should_panic(expected: 'Caller is the zero address')]
fn test_zero_addr_upgrade() {
    let (autoSwappr_contract_address, _, _) = __setup__();
    let upgradeable_dispatcher = IUpgradeableDispatcher {
        contract_address: autoSwappr_contract_address
    };

    let zero_addr: ContractAddress =
        0x0000000000000000000000000000000000000000000000000000000000000000
        .try_into()
        .unwrap();

    start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), zero_addr);
    let new_class_hash: ClassHash =
        0x0000000000000000000000000000000000000000000000000000000000000000
        .try_into()
        .unwrap();
    upgradeable_dispatcher.upgrade(new_class_hash);
}
// #[test]
// fn test_upgrade_function_wroks() {
//     let autoSwappr_contract_address = __setup__();
//     let autoSwappr_dispatcher = IAutoSwapprDispatcher {
//         contract_address: autoSwappr_contract_address
//     };

//     let owner_address: ContractAddress = OWNER.try_into().unwrap();
//     let autoswappr_address: ContractAddress = get_caller_address();
//     assert_eq!(autoswappr_address == owner_address, "Only owner is authorize to upgrade
//     contract");
//     let new_class_hash: ClassHash = ClassHash

//     start_cheat_caller_address(autoSwappr_contract_address.try_into().unwrap(), owner_address);
//     autoSwappr_dispatcher.upgrade(new_class_hash);
// }


