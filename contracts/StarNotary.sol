pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';

// import string manipulation

contract StarNotary is ERC721 { 

    struct Star { 
        string name;
        string story;
        string dec;
        string mag;
        string cent;
    }

    uint256 internal starCount = 0; 
    uint256 internal sellingCount = 0;
    uint256[] internal tokenIdsForSale; 
    mapping(uint256 => Star) public tokenIdToStar;
    mapping(uint256 => bool) internal allTokens;
    mapping(uint256 => uint256) internal _starsForSale;
    mapping (uint256 => uint256) internal _tokenIdToSerial;
    mapping (uint256 => uint256) internal _serialToTokenId;   
    mapping (uint256 => uint256) internal _serialToSellingIndex;
 
    event starCreated(address owner, uint256 tokenId);

    function createStar(
        string _name, 
        string _story,  
        string _dec, 
        string _mag,
        string _cent
        ) public returns (uint256){    

        Star memory newStar = Star({
            name: _name,
            story: _story,
            dec: _dec,
            mag: _mag,
            cent: _cent});


        uint256  _tokenId = uint256(keccak256(_strConcat(_dec, _mag, _cent)));
        require(checkIfStarExist(_tokenId) == false, "Star already exists!");
        tokenIdToStar[_tokenId] = newStar;
        _tokenIdToSerial[_tokenId] = starCount;
        _serialToTokenId[starCount] = _tokenId;
        allTokens[_tokenId] = true;
        mint(msg.sender, _tokenId);
        starCount++;

        emit starCreated(msg.sender, _tokenId);

    }

    function mint(address _to, uint256 _tokenId) internal{
        _mint(_to, _tokenId);
    }


    function checkIfStarExist (uint256 _tokenId) internal view returns (bool)  {
        return allTokens[_tokenId];
    }

    function putStarUpForSale(uint256 _tokenId, uint256 _price) public { 
        require(_isApprovedOrOwner(msg.sender,_tokenId), "Operation not permitted for user");
        _starsForSale[_tokenId] = _price;
        uint256 _serial = _tokenIdToSerial[_tokenId];
        _serialToSellingIndex[_serial] = sellingCount;
        tokenIdsForSale.push(_tokenId);
        sellingCount++;
    }


    function buyStar(uint256 _tokenId) public payable { 
        require(_starsForSale[_tokenId] > 0,"");
        
        uint256 starCost = _starsForSale[_tokenId];
        address starOwner = this.ownerOf(_tokenId);
        require(msg.value >= starCost, "");

        safeTransferFrom(starOwner, msg.sender, _tokenId);
        starOwner.transfer(starCost);

        // set price to 0 so star cannot be purchased unless the new owner desires so
        _starsForSale[_tokenId] = 0;

        // delete the entry from the selling array
        uint256 _serial = _tokenIdToSerial[_tokenId];
        uint256 _indexToDelete = _serialToSellingIndex[_serial];
        delete _serialToSellingIndex[_indexToDelete];
        sellingCount--;
        
        // shift the elements of the selling array
        if (sellingCount > 0){
            for (uint i = _indexToDelete; i<sellingCount; i++){
                tokenIdsForSale[i] = tokenIdsForSale[i+1];
                uint256 _serialSelling = _tokenIdToSerial[tokenIdsForSale[i]];
                _serialToSellingIndex[_serialSelling]--;
            }
        }
        tokenIdsForSale.length--;

        if(msg.value > starCost) { 
            msg.sender.transfer(msg.value - starCost);
        }
    }

    function starsForSale() public view returns (uint256[]){
        return tokenIdsForSale;

    }
    
    function tokenIdToStarInfo(uint256 _tokenId) external view returns (
        string _name, 
        string _story, 
        string _dec, 
        string _mag,
        string _cent){
        Star memory _star = tokenIdToStar[_tokenId];
        _name = _star.name;
        _story = _star.story;
        _dec = _strConcat("dec_", _star.dec);
        _mag = _strConcat("mag_", _star.mag);
        _cent = _strConcat("cent_", _star.cent);
    } 

    function _strConcat(string _a, string _b) internal pure returns (string){ 
        bytes memory _ba = bytes(_a); 
        bytes memory _bb = bytes(_b); 
        string memory s = new string(_ba.length + _bb.length);
        bytes memory bytes_s = bytes(s); 
        uint k = 0; 
        for (uint i = 0; i < _ba.length; i++) bytes_s[k++] = _ba[i]; 
        for (i = 0; i < _bb.length; i++) bytes_s[k++] = _bb[i]; 
        return string(bytes_s); 
    }

    function _strConcat(string _a, string _b, string _c) internal pure returns (string){ 
        //Returns the concenated coord in the format dec_rad_cent 

        bytes memory _ba = bytes(_a); 
        bytes memory _bb = bytes(_b); 
        bytes memory _bc = bytes(_c); 
        string memory s = new string(_ba.length + _bb.length + _bc.length + 2);
        bytes memory bytes_s = bytes(s); 
        uint k = 0; 
        for (uint i = 0; i < _ba.length; i++) bytes_s[k++] = _ba[i];
        bytes_s[k++] = "_";
        for (i = 0; i < _bb.length; i++) bytes_s[k++] = _bb[i]; 
        bytes_s[k++] = "_";
        for (i = 0; i < _bc.length; i++) bytes_s[k++] = _bc[i]; 
        return string(bytes_s); 
    }
}