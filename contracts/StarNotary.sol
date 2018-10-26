pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';

// import string manipulation

contract StarNotary is ERC721 { 

    struct Star { 
        string name;
        string story;
        string ra;
        string dec;
        string mag;
    }

    uint256 starCount = 0;  // used in test for uniqueness
    uint256[] tokenIdsForSale;
    mapping(uint256 => Star) public tokenIdToStar;
    mapping(uint256 => Star) public indexToStar; // used in test for uniqueness
    mapping(uint256 => uint256) public starsForSale;


    function createStar(
        string _name, 
        string _story, 
        string _ra, 
        string _dec, 
        string _mag, 
        uint256 _tokenId) public {       

        Star memory newStar = Star({
            name: _name,
            story: _story,
            ra: _ra,
            dec: _dec,
            mag: _mag});

        require(checkIfStarExist(newStar.ra, newStar.dec, newStar.mag) == false, "Star already exists!");

        indexToStar[starCount] = newStar;
        tokenIdToStar[_tokenId] = newStar;
        starCount++;

        mint(msg.sender, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) internal{
        _mint(_to, _tokenId);
    }


    function checkIfStarExist(
        string _ra, 
        string _dec,
        string _mag) internal returns (bool)  {

        for(uint i = 0; i < starCount; i++){
            if(keccak256(bytes(_ra)) == keccak256(bytes(indexToStar[i].ra)) &&
            keccak256(bytes(_dec)) == keccak256(bytes(indexToStar[i].dec)) &&
            keccak256(bytes(_mag)) == keccak256(bytes(indexToStar[i].mag))){
                return true;
            }
        }
        return false;
    }

    function putStarUpForSale(uint256 _tokenId, uint256 _price) public { 
        require(_isApprovedOrOwner(msg.sender,_tokenId), "Operation not permitted for user");
        starsForSale[_tokenId] = _price;

        //tokenIdsForSale.push(_tokenId);
    }


    function buyStar(uint256 _tokenId) public payable { 
        require(starsForSale[_tokenId] > 0,"");
        
        uint256 starCost = starsForSale[_tokenId];
        address starOwner = this.ownerOf(_tokenId);
        require(msg.value >= starCost, "");

        safeTransferFrom(starOwner, msg.sender, _tokenId);
        starOwner.transfer(starCost);

        // set price to 0 so star cannot be purchased unless the new owner desires so
        starsForSale[_tokenId] = 0;

        if(msg.value > starCost) { 
            msg.sender.transfer(msg.value - starCost);
        }
    }

    function starsForSale() public returns(uint256[]){
        tokenIdsForSale.push(123);
        return tokenIdsForSale;

    }
    
    function tokenIdToStarInfo(uint256 _tokenId) public view returns (
        string _name, 
        string _story, 
        string _ra, 
        string _dec, 
        string _mag){
        // require(tokenIdToStar[_tokenId].exists, "Token does not exist"); 
        Star memory _star = tokenIdToStar[_tokenId];
        _name = _star.name;
        _story = _star.story;
        _ra = _strConcat("ra_", _star.ra);
        _dec = _strConcat("dec_", _star.dec);
        _mag = _strConcat("mag_", _star.mag);
    } 

    function _strConcat(string _a, string _b) internal returns (string){ 
        bytes memory _ba = bytes(_a); 
        bytes memory _bb = bytes(_b); 
        string memory s = new string(_ba.length + _bb.length);
        bytes memory bytes_s = bytes(s); 
        uint k = 0; 
        for (uint i = 0; i < _ba.length; i++) bytes_s[k++] = _ba[i]; 
        for (i = 0; i < _bb.length; i++) bytes_s[k++] = _bb[i]; 
        return string(bytes_s); 
    }