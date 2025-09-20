# Collaborative Comic Creation Smart Contract

A decentralized platform for multi-creator comic series with shared ownership and automated revenue distribution on the Stacks blockchain.

## Overview

This smart contract enables multiple creators to collaborate on comic series with transparent ownership shares, automated revenue distribution, and decentralized content management. Each comic can have multiple creators with defined roles and ownership percentages.

## Features

### Core Functionality
- **Multi-Creator Comics**: Support for multiple creators per comic series
- **Shared Ownership**: Flexible ownership share distribution using basis points (1/10000)
- **Issue Publishing**: Individual issue publication with content URI storage
- **Revenue Distribution**: Automated revenue sharing based on ownership percentages
- **Access Control**: Purchase-based access to comic issues
- **Platform Fees**: Configurable platform fee collection

### Creator Management
- **Role-Based Access**: Different creator roles (founder, artist, writer, etc.)
- **Contribution Tracking**: Track individual creator contributions
- **Dynamic Addition**: Add new creators during comic development
- **Ownership Verification**: Verify creator status and ownership shares

### Content Management
- **Issue Publishing**: Publish individual comic issues with metadata
- **Content Storage**: IPFS/Arweave URI support for decentralized content
- **Series Management**: Track total issues and current publication status
- **Finalization**: Lock comic series upon completion

## Contract Structure

### Data Maps
- `comics`: Core comic series information
- `comic-creators`: Creator ownership and role data
- `creator-comics`: Creator-to-comic relationship mapping
- `comic-issues`: Individual issue metadata
- `issue-purchases`: Purchase tracking and access control

### Key Functions

#### Comic Management
- `create-comic`: Initialize new comic series
- `add-creator`: Add collaborators with ownership shares
- `finalize-comic`: Lock completed comic series
- `publish-issue`: Publish individual comic issues

#### Commerce
- `purchase-issue`: Buy access to comic issues
- `distribute-revenue`: Distribute earnings to creators
- `update-platform-fee`: Admin function for fee management

#### Read Functions
- `get-comic`: Retrieve comic information
- `get-comic-creator`: Get creator details for specific comic
- `has-purchased-issue`: Check purchase status
- `is-creator`: Verify creator status

## Usage Examples

### Creating a Comic Series

```clarity
;; Create a new comic with initial creator having 8000 basis points (80% ownership)
(create-comic
  "Super Heroes United"
  "A collaborative superhero comic series"
  u12  ;; 12 total issues
  u1000000  ;; 1 STX per issue
  "ipfs://QmExample123..."
  u8000)  ;; 80% initial ownership
```

### Adding Collaborators

```clarity
;; Add an artist with 20% ownership
(add-creator
  u1  ;; comic-id
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.artist
  u2000  ;; 20% ownership (2000 basis points)
  "artist")
```

### Publishing Issues

```clarity
;; Publish the first issue
(publish-issue
  u1  ;; comic-id
  "The Origin Story"
  "ipfs://QmIssue1Content...")
```

### Purchasing Issues

```clarity
;; Purchase access to issue 1
(purchase-issue u1 u1)
```

## Revenue Distribution Model

Revenue is distributed based on ownership percentages using basis points:
- **10000 basis points = 100% ownership**
- **1000 basis points = 10% ownership**
- **Platform fee**: Default 5% (configurable by contract owner)

### Example Distribution
For a comic earning 10 STX:
- Platform fee (5%): 0.5 STX
- Creator revenue: 9.5 STX
- Creator A (60% ownership): 5.7 STX
- Creator B (40% ownership): 3.8 STX

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_NOT_AUTHORIZED | Unauthorized access attempt |
| u101 | ERR_COMIC_NOT_FOUND | Comic or issue not found |
| u102 | ERR_ALREADY_CREATOR | User is already a creator |
| u103 | ERR_NOT_CREATOR | User is not a creator |
| u104 | ERR_INVALID_SHARE | Invalid ownership share |
| u105 | ERR_INSUFFICIENT_BALANCE | Insufficient balance |
| u106 | ERR_COMIC_FINALIZED | Comic is finalized |
| u107 | ERR_INVALID_PRICE | Invalid price setting |
| u108 | ERR_TRANSFER_FAILED | STX transfer failed |

## Security Features

- **Access Control**: Only creators can modify their comics
- **Ownership Validation**: Ownership shares validated within bounds
- **Finalization Protection**: Prevents modification of completed comics
- **Revenue Security**: Automated distribution prevents manual manipulation
- **Purchase Verification**: Duplicate purchase prevention

## Deployment

1. Deploy contract to Stacks testnet/mainnet
2. Set initial platform fee percentage
3. Configure contract owner for administrative functions

## Integration

### Frontend Integration
- Use Stacks.js for contract interactions
- Implement IPFS/Arweave for content storage
- Create user interfaces for creator collaboration

### Wallet Integration
- Support Stacks wallet connections
- Handle STX transfers for purchases
- Manage creator authentication

## Testing

Recommended test scenarios:
1. Comic creation and creator management
2. Issue publishing workflow
3. Purchase and access control
4. Revenue distribution accuracy
5. Error handling and edge cases

## Contributing

1. Follow Clarity coding standards
2. Include comprehensive tests
3. Update documentation for new features
4. Ensure security best practices

## License

MIT License - See LICENSE file for details

## Support

For technical support or questions:
- Create GitHub issues for bugs
- Submit feature requests via discussions
- Check documentation for implementation guides

---

**Note**: This contract is designed for the Stacks blockchain using Clarity smart contract language. Ensure proper testing on testnet before mainnet deployment.