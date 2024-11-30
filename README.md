# Project Description
AutoSwappr is a StarkNet-based decentralized application designed for automated token swapping, offering a one-stop solution to guard against highly volatile non-stable crypto assets. By leveraging the AVNU Exchange, it simplifies the process of auto-swapping non-stable tokens to stable ones through an upgradeable, ownable contract. AutoSwappr streamlines asset management, ensuring secure and seamless token swap processes with minimal manual intervention.

**Key functionalities:**
1. Automated subscription-based token swapping.
2. Customizable routes for multi-token swaps.
3. Upgradeable contract architecture using OpenZeppelin standards.



# Features
- Subscription Management: Users can subscribe to auto-swapping of selected tokens.
- Event Logging: Events emitted for key actions such as swaps and subscriptions.
- Upgradeability: Seamless upgrades without disrupting users' existing data.
- Fee Management: Configurable fee collector for handling transaction fees.



# Development Setup
## Prerequisites
To set up and run the project locally, ensure you have the following installed:

- [**StarkNet Foundry**](https://foundry-rs.github.io/starknet-foundry/index.html) 
- [**Scarb**](https://docs.swmansion.com/scarb/download.html)



## Starting the Development Environment

1. **Fork the Repository**

2. **Clone the Repository**

   ```sh
   git clone <repository-url>
   cd <repository-folder>
   ```


3. **Building Contracts**

   To build the contracts, use the following command:

   ```sh
   asdf local scarb 2.8.5
   ```
   This command will:
   - Setup `Scarb` via asdf


   ```sh
   asdf local starknet-foundry 0.31.0
   ```
   This command will:
   - Setup `starknet-foundry` via asdf


   ```sh
   scarb build
   ```
   This command will:
   - Build the contract


4. **Running Tests**
   To run the unit tests, use the command:

   ```sh
   snforge test
   ```

5. **Pull Requests**
   - Ensure your branch is up to date with the main branch.
   - Push your changes and open a PR against `master`.
   - Provide a detailed description of your changes.

6. **Coding Standards**
   - **Cairo Code:** Follow the [Cairo documentation](https://www.cairo-lang.org/docs/) and best practices.
   - **ASDF:** Follow the [asdf installation](https://asdf-vm.com/guide/getting-started.html) instructions
   - **Testing:** Write tests for your code and ensure all tests pass before submitting a PR.
