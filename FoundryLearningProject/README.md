# Foundry Learning Project

This project demonstrates how to use Foundry for Solidity development, testing, and gas optimization.

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   forge install
   ```

## Usage

### Compile Contracts

```bash
forge build
```

### Run Tests

```bash
forge test
```

### Run Gas Tests

To run gas tests and generate a gas report:

```bash
forge test --gas-report
```

Or use the provided script:

```bash
./run_gas_report.bat
```

### Gas Optimization Analysis

See [GAS_ANALYSIS.md](GAS_ANALYSIS.md) for a detailed analysis of gas consumption between the standard and optimized contracts.

## Project Structure

- `src/`: Solidity contracts
- `test/`: Test files
- `script/`: Deployment scripts
- `GAS_ANALYSIS.md`: Gas consumption analysis
- `run_gas_report.bat`: Script to run gas tests and generate reports

## Learn More

To learn more about Foundry, check out the [official documentation](https://book.getfoundry.sh/).