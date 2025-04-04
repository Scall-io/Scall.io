// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "hardhat/console.sol";

contract ERC721_Enumerable is ERC721Enumerable {
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    function mint(address _to, uint256 _id) external {
        _safeMint(_to, _id);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function isPartOf(address _x, address[] memory _array) public pure returns(bool) {
        for(uint256 i ; i < _array.length ; i++) {
            if (_x == _array[i]) {
                return true;
            }
        }
        return false;
    }

    function getOwners() public view returns(address[] memory) {
        uint256 ID;
        address owner;        
        uint256 count;

        // Get all owners
        address[] memory _owners = new address[](totalSupply());
        for(uint256 i ; i < totalSupply() ; i++) {
            ID = tokenByIndex(i);
            owner = ownerOf(ID);
            if (!isPartOf(owner, _owners)) {
                _owners[count] = owner;
                count++;
            } 
        }

        // Remove clones
        address[] memory owners = new address[](count);
        for(uint256 ii ; ii < count ; ii++) {
            owners[ii] = _owners[ii];
        }

        return owners;
    }
    
}
