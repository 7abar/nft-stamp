# nft-stamp

> Proof of attendance. Fully onchain. No IPFS. No servers. No expiry date.

NFT Stamp lets event organizers deploy an ERC-721 contract with **fully onchain SVG metadata**. Attendees mint a stamp as permanent proof they were there. The NFT image and metadata live entirely in the blockchain — no external dependencies, ever.

## Why Onchain SVG?

- No IPFS pinning to maintain
- No metadata server to keep running
- No one can pull the rug on your artwork
- Works forever, as long as Ethereum exists

## Deploy

Set your event parameters and deploy:

```bash
forge install foundry-rs/forge-std
forge build

EVENT_NAME="ETHGlobal Bangkok" \
EVENT_DATE="Nov 2025" \
MAX_SUPPLY=100 \
MINT_PRICE=1000000000000000 \
forge script script/Deploy.s.sol \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --private-key $PK
```

### Constructor Parameters

| Parameter | Description | Example |
|---|---|---|
| `EVENT_NAME` | Event name shown on NFT | `"ETHGlobal Bangkok"` |
| `EVENT_DATE` | Event date shown on NFT | `"Nov 2025"` |
| `MAX_SUPPLY` | Max number of stamps | `100` |
| `MINT_PRICE` | Price per stamp in wei | `1000000000000000` (0.001 ETH) |

## Mint a Stamp

```bash
cast send $CONTRACT "mint()" \
  --value 0.001ether \
  --rpc-url https://mainnet.base.org \
  --private-key $PK
```

## Read Metadata

The metadata is fully onchain — call `tokenURI` and decode the base64:

```bash
# Get token URI (returns base64-encoded JSON with embedded SVG)
cast call $CONTRACT "tokenURI(uint256)" 0 --rpc-url https://mainnet.base.org

# Check total minted
cast call $CONTRACT "totalSupply()" --rpc-url https://mainnet.base.org

# Check if minting is open
cast call $CONTRACT "mintingOpen()" --rpc-url https://mainnet.base.org
```

## Owner Controls

```bash
# Close minting
cast send $CONTRACT "closeMinting()" --private-key $OWNER_PK --rpc-url https://mainnet.base.org

# Open minting again
cast send $CONTRACT "openMinting()" --private-key $OWNER_PK --rpc-url https://mainnet.base.org

# Withdraw proceeds
cast send $CONTRACT "withdraw()" --private-key $OWNER_PK --rpc-url https://mainnet.base.org
```

## Test

```bash
forge test -vv
```

## Contract Interface

| Function | Description |
|---|---|
| `mint()` | Mint a stamp (payable) |
| `tokenURI(tokenId)` | Get fully onchain metadata |
| `closeMinting()` | Owner: stop minting |
| `openMinting()` | Owner: resume minting |
| `withdraw()` | Owner: collect ETH |
| `totalSupply()` | Count of minted stamps |

## NFT Preview

The stamp renders as a dark SVG card with:
- Event name
- Event date  
- Token ID
- "PROOF OF ATTENDANCE" label
- Checkmark in an indigo circle

---

> *The NFT metadata lives entirely onchain. No IPFS. No server. No rug.*
