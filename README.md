## VoxBox: Decentralized Voting System

**Overview**

VoxBox is a decentralized voting system implemented as a smart contract on the Ethereum blockchain. Designed with a focus on security and gas efficiency, VoxBox enables transparent and fair voting processes, featuring voter registration, candidate addition, vote delegation, and efficient winner determination.

**Features**

-  **Voting Period Control**: Voting is restricted within a specified time frame.
-  **Voter Registration**: Users can register to vote during the active voting period.
-  **Candidate Management**: The contract owner can add candidates to the ballot.
-  **Vote Delegation**: Voters can delegate their votes to other registered voters.
-  **Efficient Winner Determination**: Utilizes dynamic tracking of leading candidates to determine election winners.
-  **Transparency and Security**: Built on Ethereum for a transparent, secure, and immutable voting process.
-  **Custom Error Handling**: Improved clarity and gas savings through custom error messages.




## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
