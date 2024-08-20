pragma solidity ^0.8.12;                

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./gearsMetadataUtils.sol";
import "./gearsTypesV1.sol";

contract gearsV1 is ERC721, ERC721Burnable, Ownable2Step, gearsMetadataUtils {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _xn;
    //tokenId -> gearsMetadata
    mapping(string => uint256) private _xnToTokenId;
    mapping(uint256 => gearsInfo) public gears;
    uint256 public gearsCount;

    string[] private _xnVersions = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
        "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
        "u", "v", "w", "x", "y", "z", "aa", "ab", "ac", "ad",
        "ae", "af", "ag", "ah", "ai", "aj"
    ];

    event gearsMinted(address indexed creator, uint256 tokenId, string xn);
    event gearsUpgraded(address indexed creator, uint256 tokenId, string xn, uint256 originTokenId);

    mapping(uint256 => uint256) private _tokenIdLenToMintPrice;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _xn.increment();
        _tokenIdLenToMintPrice[36] = 0.006 ether;
        _tokenIdLenToMintPrice[35] = 0.007 ether;
        _tokenIdLenToMintPrice[34] = 0.009 ether;
        _tokenIdLenToMintPrice[33] = 0.011 ether;
        _tokenIdLenToMintPrice[32] = 0.013 ether;
        _tokenIdLenToMintPrice[31] = 0.016 ether;
        _tokenIdLenToMintPrice[30] = 0.020 ether;
        _tokenIdLenToMintPrice[29] = 0.024 ether;
        _tokenIdLenToMintPrice[28] = 0.029 ether;
        _tokenIdLenToMintPrice[27] = 0.035 ether;
        _tokenIdLenToMintPrice[26] = 0.043 ether;
        _tokenIdLenToMintPrice[25] = 0.053 ether;
        _tokenIdLenToMintPrice[24] = 0.064 ether;
        _tokenIdLenToMintPrice[23] = 0.078 ether;
        _tokenIdLenToMintPrice[22] = 0.095 ether;
        _tokenIdLenToMintPrice[21] = 0.116 ether;
        _tokenIdLenToMintPrice[20] = 0.141 ether;
        _tokenIdLenToMintPrice[19] = 0.172 ether;
        _tokenIdLenToMintPrice[18] = 0.209 ether;
        _tokenIdLenToMintPrice[17] = 0.255 ether;
        _tokenIdLenToMintPrice[16] = 0.311 ether;
        _tokenIdLenToMintPrice[15] = 0.379 ether;
        _tokenIdLenToMintPrice[14] = 0.461 ether;
        _tokenIdLenToMintPrice[13] = 0.562 ether;
        _tokenIdLenToMintPrice[12] = 0.684 ether;
        _tokenIdLenToMintPrice[11] = 0.834 ether;
        _tokenIdLenToMintPrice[10] = 1.016 ether;
        _tokenIdLenToMintPrice[9] = 1.237 ether;
        _tokenIdLenToMintPrice[8] = 1.507 ether;
        _tokenIdLenToMintPrice[7] = 1.836 ether;
        _tokenIdLenToMintPrice[6] = 2.237 ether;
        _tokenIdLenToMintPrice[5] = 2.725 ether;
        _tokenIdLenToMintPrice[4] = 3.319 ether;
        _tokenIdLenToMintPrice[3] = 4.043 ether;
        _tokenIdLenToMintPrice[2] = 4.925 ether;
        _tokenIdLenToMintPrice[1] = 6.000 ether;
        gearsCount = 0;
    }

    function _checkTokenId(uint256 tokenId) internal pure returns(uint256) {
        require(
            tokenId >= 1 && tokenId < 10 ** 36,
            "Invalid gears pattern length"
        );

        //remove trailing 6's
        while (tokenId % 10 == 6) {
            tokenId /= 10;
        }

        //get number of digits
        uint8 numDigits = 0;
        uint256 tempTokenId = tokenId;
        while (tempTokenId != 0) {
            numDigits++;
            tempTokenId /= 10;
        }

        // verify digits are between 1-6
        for (uint8 i = 0; i < numDigits; i++) {
            // Get the i-th digit of gearPattern
            uint256 digit = (tokenId / (10 ** i)) % 10;

            // Check if the digit is between 1-6
            require(
                digit >= 1 && digit <= 6,
                "Invalid digit value gears pattern"
            );
        }
        return numDigits;
    }

    function getAllTokenIds() public view returns (uint256[] memory){
        uint256[] memory ret = new uint256[](gearsCount);
        uint256 cur_xn = _xn.current();
        uint256 i = 0;
        for (uint256 xn=1; xn<cur_xn; xn++) {
            for (uint256 j=0; i<36; j++) {
                string memory xn_str;
                if (j == 0) { // 'a'
                    xn_str = xn.toString(); // xn-[num]
                } else {
                    xn_str = string.concat(xn.toString(), "-", _xnVersions[j]);  // xn-[num]-[xnVersion]
                }                
                if (_xnToTokenId[xn_str] != 0) {
                    ret[i] = _xnToTokenId[xn_str];
                    i++;
                } else {
                    break;
                }
            }
        }
        return ret;
    }

    function getMintPrice(uint256 tokenId) public view returns (uint256) {
        uint256 numDigits = _checkTokenId(tokenId);
        uint256 mintPrice = _tokenIdLenToMintPrice[numDigits];
        return mintPrice;
    }

    function upgradegears(
        address creator,
        uint256 tokenId,
        string memory description,
        uint256 originTokenId
    ) public payable returns (uint256) {
        uint256 length = bytes(description).length;
        require(
            length < 36 && length > 0,
            "gears description must be greater than 0 bytes and less than 36 bytes"
        );

        uint256 originTokenIdLen = _checkTokenId(originTokenId);
        uint256 tokenIdLen = _checkTokenId(tokenId);

        require(
            originTokenIdLen > tokenIdLen,
            "Cannot downgrade the level"
        );

        uint256 mintPrice = _tokenIdLenToMintPrice[tokenIdLen] - _tokenIdLenToMintPrice[originTokenIdLen];
        require(
            msg.value >= mintPrice,
            "eth paid is less than the mint price"
        );

        require(
            _exists(originTokenId),
            "nonexistent original token"
        );

        require(
            ownerOf(originTokenId) == msg.sender,
            "not token owner"
        );

        // get origin XN by tokenId
        gearsInfo memory origingearsObj = gears[originTokenId];

        // get new XN
        int256 idx = -1;
        for (int256 i = 0; i < 36; i++) {
            if (keccak256(abi.encodePacked(_xnVersions[uint256(i)])) == keccak256(abi.encodePacked(origingearsObj.xnVersion))) {
                idx = i;
                break;
            }
        }

        uint256 xn = origingearsObj.xn; // keep origin token XN
        uint256 newIdx = uint256(idx + 1);

        string memory xnVersion;  // change XN version
        string memory xn_str;

        if (newIdx == 0) { // 'a'
            xnVersion = '';
            xn_str = xn.toString();
        } else {
            xnVersion = _xnVersions[newIdx];
            xn_str = string.concat(xn.toString(), "-", xnVersion);
        }

        _safeMint(creator, tokenId);
        gearsCount++;
        gears[tokenId] = gearsInfo(description, creator, xn, xnVersion, false);
        _xnToTokenId[xn_str] = tokenId;

        burn(originTokenId);
        gears[originTokenId].burnStatus = true;

        emit gearsUpgraded(creator, tokenId, xn_str, originTokenId);
        return tokenId;
    }

    // Allows minting of a new NFT
    function mintgears(
        address creator,
        uint256 tokenId,
        string memory description
    ) public payable returns (uint256) {

        uint256 length = bytes(description).length;
        require(
            length < 36 && length > 0,
            "gears description must be greater than 0 bytes and less than 36 bytes"
        );

        uint256 numDigits = _checkTokenId(tokenId);

        require(
            msg.value >= _tokenIdLenToMintPrice[numDigits],
            "eth paid is less than the mint price"
        );

        //mint
        uint256 xn = _xn.current();
        string memory xn_str = xn.toString();
        _safeMint(creator, tokenId);
        gearsCount++;
        gears[tokenId] = gearsInfo(description, creator, xn, "a", false);
        _xnToTokenId[xn_str] = tokenId;
        _xn.increment();
        emit gearsMinted(creator, tokenId, xn_str);
        return tokenId;
    }

    // for Opensea - it doesn't return the token URI of burned token.
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return generateTokenURI(tokenId, gears[tokenId]);
    }

    // Returns the token URI even if it was burned.
    function tokenURIByTokenId(uint256 tokenId) public view returns (string memory) {
        require(
            gears[tokenId].creator != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return generateTokenURI(tokenId, gears[tokenId]);
    }

    function tokenURIByXN(string memory xn) public view returns (string memory) {
        require(
            _xnToTokenId[xn] != 0,
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 tokenId = _xnToTokenId[xn];
        return generateTokenURI(tokenId, gears[tokenId]);
    }

    function creatorOf(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721Metadata: creator query for nonexistent token"
        );
        return gears[tokenId].creator;
    }

    function isAvailable(uint256 tokenId) public view returns (bool) {
        return gears[tokenId].creator == address(0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "amount exceeds balance");
        payable(msg.sender).transfer(amount);
    }
}