# EducationVote

EducationVote is an academic democracy platform for curriculum development and teaching methodology approval built on the Stacks blockchain. This smart contract enables academic institutions to create and vote on curriculum proposals and teaching methodologies in a decentralized, transparent manner.

## Overview

The EducationVote smart contract provides a secure voting system where authorized academic stakeholders can propose and vote on educational initiatives. The platform ensures democratic decision-making while maintaining institutional oversight through an authorization system.

## Features

- **Proposal Creation**: Authorized users can create proposals for curriculum changes or teaching methodology updates
- **Democratic Voting**: Secure voting mechanism with one vote per authorized user
- **Proposal Types**: Support for both "curriculum" and "methodology" proposal categories
- **User Authorization**: Admin-controlled authorization system for voters
- **User Profiles**: Academic credential tracking with institution, department, and role information
- **Automatic Finalization**: Proposals are automatically finalized after voting period ends
- **Transparent Results**: All votes and results are recorded on the blockchain
- **Minimum Voting Period**: Ensures adequate time for community participation (minimum 1 day)

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Contract Name**: EducationVote
- **Version**: 1.0.0

### Key Components

- **Proposals**: Store proposal details including title, description, voting period, and results
- **Authorized Voters**: Whitelist of users permitted to create proposals and vote
- **User Profiles**: Academic credentials and institutional affiliations
- **Vote Tracking**: Prevention of double voting and vote result tallying
- **Status Management**: Proposal lifecycle from active to passed/rejected

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- [Node.js](https://nodejs.org/) (version 14 or higher)
- [Stacks wallet](https://www.hiro.so/wallet) for testnet/mainnet deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd EducationVote
```

2. Install dependencies:
```bash
cd EducationVote_contract
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests (if available):
```bash
clarinet test
```

## Usage Examples

### Initialize the Contract

```clarity
;; Initialize the contract (only contract owner)
(contract-call? .EducationVote initialize)
```

### Add Authorized Voters

```clarity
;; Add a professor as authorized voter
(contract-call? .EducationVote add-authorized-voter
    'SP1HTBVD3S5VVJVFWZ4XVWT7D4QPZYP1F2G3H4J5
    u"University of Example"
    u"Computer Science"
    u"professor")
```

### Create a Proposal

```clarity
;; Create a curriculum proposal
(contract-call? .EducationVote create-proposal
    u"Introduce AI Ethics Course"
    u"Add a mandatory course on AI ethics for all CS students to address growing concerns about AI impact on society"
    u"curriculum"
    u288) ;; 2 days voting period
```

### Vote on a Proposal

```clarity
;; Vote in favor of proposal #1
(contract-call? .EducationVote vote-on-proposal u1 true)

;; Vote against proposal #1
(contract-call? .EducationVote vote-on-proposal u1 false)
```

### Finalize a Proposal

```clarity
;; Finalize proposal after voting period ends
(contract-call? .EducationVote finalize-proposal u1)
```

## Contract Functions Documentation

### Public Functions

#### `initialize()`
- **Purpose**: Initialize the contract owner as the first authorized voter
- **Access**: Contract owner only
- **Returns**: `(ok true)` on success

#### `add-authorized-voter(voter, institution, department, role)`
- **Purpose**: Add a new authorized voter with academic credentials
- **Parameters**:
  - `voter`: Principal address of the new voter
  - `institution`: University or institution name (max 256 chars)
  - `department`: Academic department (max 128 chars)
  - `role`: Academic role (max 64 chars, e.g., "professor", "admin", "student")
- **Access**: Contract owner only
- **Returns**: `(ok true)` on success

#### `remove-authorized-voter(voter)`
- **Purpose**: Remove an authorized voter (maintains minimum of 1 voter)
- **Parameters**: `voter` - Principal address to remove
- **Access**: Contract owner only
- **Returns**: `(ok true)` on success

#### `create-proposal(title, description, proposal-type, voting-duration)`
- **Purpose**: Create a new proposal for voting
- **Parameters**:
  - `title`: Proposal title (max 256 chars)
  - `description`: Detailed description (max 1024 chars)
  - `proposal-type`: Either "curriculum" or "methodology"
  - `voting-duration`: Voting period in blocks (minimum 144 blocks ≈ 1 day)
- **Access**: Authorized voters only
- **Returns**: `(ok proposal-id)` with the new proposal ID

#### `vote-on-proposal(proposal-id, vote-for)`
- **Purpose**: Cast a vote on an active proposal
- **Parameters**:
  - `proposal-id`: ID of the proposal to vote on
  - `vote-for`: Boolean (true for yes, false for no)
- **Access**: Authorized voters only (one vote per voter per proposal)
- **Returns**: `(ok true)` on successful vote

#### `finalize-proposal(proposal-id)`
- **Purpose**: Finalize a proposal after voting period ends
- **Parameters**: `proposal-id` - ID of the proposal to finalize
- **Access**: Anyone can call after voting period ends
- **Returns**: `(ok status)` where status is the final result (2 = passed, 3 = rejected)

### Read-Only Functions

#### `get-proposal(proposal-id)`
- **Purpose**: Retrieve proposal details
- **Returns**: Proposal data or none if not found

#### `get-vote(proposal-id, voter)`
- **Purpose**: Get a specific voter's choice for a proposal
- **Returns**: Boolean vote choice or none if not voted

#### `is-authorized-voter(user)`
- **Purpose**: Check if a user is authorized to vote
- **Returns**: Boolean authorization status

#### `get-user-profile(user)`
- **Purpose**: Retrieve user's academic profile
- **Returns**: Profile data including institution, department, role, and verification status

#### `get-proposal-counter()`
- **Purpose**: Get the total number of proposals created
- **Returns**: Current proposal counter value

#### `get-authorized-voters-count()`
- **Purpose**: Get the total number of authorized voters
- **Returns**: Count of authorized voters

#### `is-voting-active(proposal-id)`
- **Purpose**: Check if voting is still active for a proposal
- **Returns**: Boolean indicating if voting is open

## Deployment Guide

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --mainnet
```

### Post-Deployment Setup

1. Initialize the contract:
```bash
clarinet console --testnet
```

2. Call the initialize function:
```clarity
(contract-call? .EducationVote initialize)
```

3. Add initial authorized voters as needed

## Security Considerations

### Access Control
- Only the contract owner can add/remove authorized voters
- Only authorized voters can create proposals and vote
- Each voter can only vote once per proposal

### Voting Integrity
- Votes are immutable once cast
- Double voting is prevented through vote tracking
- Voting periods are enforced at the blockchain level

### Proposal Validation
- Proposal types are restricted to "curriculum" and "methodology"
- Minimum voting periods ensure adequate deliberation time
- Automatic finalization prevents manipulation after voting ends

### Best Practices
- Regularly audit authorized voter list
- Ensure institutional representation in voter authorization
- Monitor proposal activity for suspicious patterns
- Implement off-chain verification for high-impact proposals

## Error Codes

- `100`: Not authorized - User lacks required permissions
- `101`: Proposal not found - Invalid proposal ID
- `102`: Voting ended - Proposal voting period has expired
- `103`: Already voted - User has already cast a vote on this proposal
- `104`: Invalid proposal - Proposal type must be "curriculum" or "methodology"
- `105`: Insufficient balance - Reserved for future use

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly using Clarinet
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

For questions or support, please create an issue in the repository or contact the development team.