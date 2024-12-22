# AutoSwappr

AutoSwappr is a Starknet-based DeFi solution designed for automated token swapping, offering a one-stop solution to guard against highly volatile non-stable crypto assets. By leveraging DEX aggregators, it simplifies the process of auto-swapping non-stable crypto assets to stable assets ensuring secure and seamless token swap processes with minimal manual intervention.

## Features

### Core Functionality

- Automated Token Swapping: subscription-based system for automated conversion of assets
- Multi-Route Support: flexible routing options for complex token swaps
- Real-time Event Tracking: comprehensive event logging for swaps and subscriptions

### Technical Features

- Upgradeable Architecture: leverages OpenZeppelin's upgradeable contract 
- Custom Route Configuration: built-in support for multi-token swap routes

## Architecture

AutoSwappr is built on Starknet and implements:

    - OpenZeppelin standards for upgradeability
    - DEX aggregators for swap execution
    - Event-driven architecture for transaction tracking

## Getting Started

## Prerequisites

To set up and run the project locally, ensure you have the following installed:

- [**Starknet Foundry**](https://foundry-rs.github.io/starknet-foundry/index.html)
- [**Scarb**](https://docs.swmansion.com/scarb/download.html)
- [**ASDF Version Manager**](https://asdf-vm.com/guide/getting-started.html)

## Installation

1. **Fork the Repository**

2. **Clone the Repository to your local machine**

```bash
   git clone https://github.com/BlockheaderWeb3-Community/auto-swap
   cd auto-swap
```

3. **Set Up Development Environment**
   To set up development environment:

```bash
    # Configure Scarb version
    asdf local scarb 2.8.5

    # Configure StarkNet Foundry
   asdf local starknet-foundry 0.31.0
```


4. Build the Project:

```bash
   scarb build
```

## Development

### Building

The project uses Scarb as its build tool. To build the contracts:

```bash
scarb build
```

## Testing

Run the test suite using Starknet Foundry:

```bash
snforge test
```

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (git checkout -b revoke-allowance)
3. Commit your changes (git commit -m 'test: revoke allowance')
4. Push to the branch (git push origin revoke-allowance)
5. Open a Pull Request



## Pull Request Process

1. Ensure your branch is up to date with main
2. Include relevant test cases
3. Update documentation as needed
4. Provide a detailed description of changes
5. Request review from maintainers

## Support

For support and queries:

- Open an issue in the GitHub repository
- Join our [Telegram channel](https://t.me/+TXSDWeFXReAxMzk0)

---

Built with ❤️ by the BlockheaderWeb3 Community
