// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NFTStamp
/// @notice Mint an NFT as proof you were at an event or milestone.
/// @dev ERC-721 with onchain SVG metadata. No external dependencies.
contract NFTStamp {
    // ── ERC-721 minimal implementation ──────────────────────────────────────
    string public name;
    string public symbol;
    uint256 private _nextTokenId;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _approvals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ── Stamp-specific ───────────────────────────────────────────────────────
    address public owner;
    bool public mintingOpen;
    uint256 public maxSupply;
    uint256 public mintPrice;

    struct Stamp {
        string eventName;
        string eventDate;
        uint256 mintedAt;
    }

    mapping(uint256 => Stamp) public stamps;

    event StampMinted(address indexed to, uint256 indexed tokenId, string eventName);

    error NotOwner();
    error MintingClosed();
    error MaxSupplyReached();
    error WrongPrice();
    error NotTokenOwner();
    error ZeroAddress();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _eventName,
        string memory _eventDate,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        mintingOpen = true;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        stamps[type(uint256).max] = Stamp(_eventName, _eventDate, block.timestamp);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function mint() external payable {
        if (!mintingOpen) revert MintingClosed();
        if (_nextTokenId >= maxSupply) revert MaxSupplyReached();
        if (msg.value != mintPrice) revert WrongPrice();

        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender]++;

        stamps[tokenId] = Stamp({
            eventName: stamps[type(uint256).max].eventName,
            eventDate: stamps[type(uint256).max].eventDate,
            mintedAt: block.timestamp
        });

        emit Transfer(address(0), msg.sender, tokenId);
        emit StampMinted(msg.sender, tokenId, stamps[tokenId].eventName);
    }

    function closeMinting() external onlyOwner { mintingOpen = false; }
    function openMinting() external onlyOwner { mintingOpen = true; }
    function withdraw() external onlyOwner {
        (bool ok,) = owner.call{value: address(this).balance}("");
        require(ok);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "nonexistent token");
        Stamp memory s = stamps[tokenId];
        string memory svg = _buildSVG(s, tokenId);
        string memory json = string(abi.encodePacked(
            '{"name":"', s.eventName, ' #', _toString(tokenId),
            '","description":"Proof of attendance: ', s.eventName,
            '","attributes":[{"trait_type":"Event","value":"', s.eventName,
            '"},{"trait_type":"Date","value":"', s.eventDate,
            '"},{"trait_type":"Token ID","value":"', _toString(tokenId), '"}]',
            ',"image":"data:image/svg+xml;base64,', _base64(bytes(svg)), '"}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", _base64(bytes(json))));
    }

    function _buildSVG(Stamp memory s, uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">',
            '<rect width="300" height="300" fill="#050510"/>',
            '<rect x="10" y="10" width="280" height="280" fill="none" stroke="#6366f1" stroke-width="2"/>',
            '<circle cx="150" cy="90" r="40" fill="none" stroke="#6366f1" stroke-width="2"/>',
            '<text x="150" y="97" font-family="monospace" font-size="28" fill="#6366f1" text-anchor="middle">&#10003;</text>',
            '<text x="150" y="160" font-family="monospace" font-size="13" fill="#e8e8f0" text-anchor="middle">', s.eventName, '</text>',
            '<text x="150" y="185" font-family="monospace" font-size="10" fill="#6366f1" text-anchor="middle">', s.eventDate, '</text>',
            '<text x="150" y="260" font-family="monospace" font-size="9" fill="#55557a" text-anchor="middle">PROOF OF ATTENDANCE</text>',
            '<text x="150" y="278" font-family="monospace" font-size="8" fill="#55557a" text-anchor="middle">#', _toString(tokenId), '</text>',
            '</svg>'
        ));
    }

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert ZeroAddress();
        return _balances[_owner];
    }
    function ownerOf(uint256 tokenId) external view returns (address) {
        address o = _owners[tokenId];
        require(o != address(0), "nonexistent");
        return o;
    }
    function totalSupply() external view returns (uint256) { return _nextTokenId; }
    function approve(address to, uint256 tokenId) external {
        address o = _owners[tokenId];
        require(msg.sender == o || _operatorApprovals[o][msg.sender], "not authorized");
        _approvals[tokenId] = to;
        emit Approval(o, to, tokenId);
    }
    function getApproved(uint256 tokenId) external view returns (address) { return _approvals[tokenId]; }
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address o, address operator) external view returns (bool) { return _operatorApprovals[o][operator]; }
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_owners[tokenId] == from, "wrong owner");
        require(
            msg.sender == from ||
            msg.sender == _approvals[tokenId] ||
            _operatorApprovals[from][msg.sender],
            "not authorized"
        );
        if (to == address(0)) revert ZeroAddress();
        delete _approvals[tokenId];
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        this.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        this.transferFrom(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x01ffc9a7;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) { digits--; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10; }
        return string(buffer);
    }
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function _base64(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for { let i := 0 } lt(i, len) {} {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
