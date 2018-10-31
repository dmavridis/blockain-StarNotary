# Decentralized Star notary project
For this project, you will create DApp notary service leveraging the Ethereum platform. You write smart contract that offer securely prove the existence for any digital asset - in this case unique stars and their metadata!

## Approach for the implementation
The notary system consists of the struct of the star and a unique tokenId generated from the hashing of the star coordinations. An additional  variable acting as a serial number, is noting the sequence of creation. Two mappings, `_tokenIdToSerial` and `_serialToTokenId` map those two values in both directions. An example is:

```
_tokenIdToSerial = {1234: 0, 5678: 1, 2468: 2, 1357: 3}
_serialToTokenId = {0: 1234, 1:5678, 2:2468, 3:1357}

```
The `tokenIdToStar` maps the tokenId to the star struct. The variable `starCount` holds the length of the arrays, which is the number of the added stars. In the example above it has a value 4.

For selling iterms the array `tokenIdsForSale` holds the tokens of the stars for sale. The mapping `_serialToSellingIndex` maps the serial number of the stars for sale to their index in the array. An example can be: 

```
tokenIdsForSale = [2468, 1357]
_serialToSellingIndex = {2:0, 3:1}
```
A counting variable `sellingCount` holds the number of available items and in this case is 2. When an item is bought by another user, it has to be removed from the list. Due to limitations of solidity, when an item is deleted, its value just becomes 0. Then, the rest of the data are shifted to the left and the _serialToSellingIndex of all the following elements is decreased by one. 

For example when star with tokenId 2468 is removed from the array, the values from above become:

```
tokenIdsForSale = [1357]
_serialToSellingIndex = {2:0, 3:0}
```

## Write a smart contract with functions
The project items, stars in this case, are non-fungible tokens. The ERC721 protocol is used implemented in the OpenZeppelin library.

The star itself is a struct consisting of the following items:
- Name
- Star coordinators
  - Dec
  - Mag
  - Cent
- Star story

The tokenId is derived from the expression:
```
tokenId = keccak256(concatenate(Dec, Mag, Cent))
```
The implemented functions with some information of their implementations are described in the next paragraphs. 

### Create a star
The following functions are used for creating a star:

```
createStar(name, story, dec, mag, cent)

checkIfStarExist(tokenId)

mint(to, tokenId)
```


The star creation requires the user to provide the Star Data and a tokenID for the star.

In the contract, there are two mappings that are necessary to implement the various functions.

- tokenIdToStar: When star creation is succesfull an entry is creared with the tokenId as the index and the star as the value
- tokenIdToCount: This mapping maps the tokenId to a serial number. First star corresponds to 0, second to 1, etc. This mapping is helpful to iterate over existing stars.

When the createStar function is called, there is a check for uniqueness according to the coordinates. If a star already exists in the particular position, the creation fails. 

When succesful, the Star is minted, assigning its ownership to the creators address. 


### Get star info
`tokenIdToStarInfo(tokenId)`

The function returns star information in the following format: `["Star power 103!", "I love my wonderful star", "ra_032.155", "dec_121.874", "mag_245.978"]`. To add the prefixes in the coordinates value, a implemented concatenation function is called. 


### Put star up for sale
The following functions are used for putting a star to sale:

`putStarUpForSale(tokenId)`

When an allowed party is putting the star to sale, its serial number is added to the mapping TODO, with the desired selling value. The serial number is also added to the array snToSale. The function `starsForSale()` is showing to potential buyers the available stars.

### Buy s star
The following functions are used for buying a star:

```
buyStar(tokenId)

safeTransferFrom(from, to, tokenId)
```

The `buyStar` function calls the `safeTransferFrom` function to change the ownership, performs the monetary transaction and also removes the star from the list of stars to buy. 

### Owneship related functions
The following functions are implemented in openzeppelin library and are used in buying and selling star operations, setting the permission of entities that are allowed to sell a star. The owner can delegate the action of selling to other parties from one or all of their possesions. 

 ```
 approve(to, tokenId)

 setApprovalForAll(to, approved)

isApprovedForAll(owner, operator)

ownerOf(tokenId)
```

## Test smart contract code coverage

The following sets of tests are performed in javascript

- Star test
  - can create a star and get its name: checked `createStar`
  - check if star exists: checked `checkIfStarExist`
  - token Id to star info: checked `tokenIdToStarInfo`
- Buying and selling stars tests
  - user1 can put up their star for sale: checked `putStarUpForSale`
  - user2 can buy a star that was put up for sale: checked `buyStar`, `safeTransferFrom`, `mint`, `ownerOf`
  - user2 ether balance changed correctly: checked `buyStar`, `safeTransferFrom`
  - another user cannot buy the star from the new owner: checked `buyStar`, `safeTransferFrom`
- Sell a star through an approved user
  - user1 approves approver for star2: checked `approve`
  - approver puts star2 to sale and user2 buys:checked `buyStar`, `safeTransferFrom`
  - sell two stars with setApproveForAll function: checked `setApprovalForAll`, `starsForSale`
  
Finally, `getApproved` and `isApprovedForAll` are function implemented in openZeppelin and since the above testing is correct, by induction and they are also correctly implemented. 


### Testing output
```
Contract: StarNotary
    Star test
      ✓ can create a star and get its name (99ms)
      ✓ check if star exists (160ms)
      ✓ token Id to star info (183ms)
    Buying and selling stars tests
      ✓ user1 can put up their star for sale (61ms)
      user2 can buy a star that was put up for sale
        ✓ user2 is the owner of the star after they buy it (92ms)
        ✓ user2 ether balance changed correctly (179ms)
        ✓ another user cannot buy the star from the new owner (100ms)
      sell a star through an approved user
        ✓ user1 approves approver for star2 (62ms)
        ✓ approver puts star2 to sale and user2 buys (203ms)
[ BigNumber { s: 1, e: 3, c: [ 2468 ] },
  BigNumber { s: 1, e: 3, c: [ 1357 ] } ]
[ BigNumber { s: 1, e: 3, c: [ 1357 ] } ]
[]
        ✓ sell two stars with setApproveForAll function (343ms)


  10 passing (4s)

```

## Deploy smart contract on a public test network (Rinkeby)

Running the command `truffle deploy --network rinkeby` the contract is deployed to the test network. The output is the following:

```
Using network 'rinkeby'.

Running migration: 1_initial_migration.js
  Deploying Migrations...
  ... 0xb8db8cd389a24064c54627640c17fe589b2a3515a4527bf6d7d5e70df71ca53c
  Migrations: 0x5b4eb21ebc65808c5146cc030aaa32787023e34e
Saving successful migration to network...
  ... 0x152dcdc9c6bd128edbd0a3aee6e0cb4a92876d01d818c5463d9e2e0cd489ba6e
Saving artifacts...
Running migration: 2_star_notary.js
  Deploying StarNotary...
  ... 0x1d2fe85b41cc43b09299e6f54ddaf5e977b7ef7c23ad94729d63136cf009507b
  StarNotary: 0x5389a0387e0e987a4697cd962889a3c32a33d559
Saving successful migration to network...
  ... 0x6082f0779d6f86f618fc28375df0f5009d1dfeadd29889b47cf285bc406d1d82
Saving artifacts...

```
The smart contract address is found in: https://rinkeby.etherscan.io/address/0x5389a0387e0e987a4697cd962889a3c32a33d559

In https://www.myetherwallet.com/, a star is created with the following information: 
```
name: 'Dimi Star'
story: 'My great star!'
dec: 14.53
mag: 18.21
cent: 10.40
```
and the transaction hash is: `0xcf5418715b77de0e8b0b4d983ee0d58b8b96ef95d6ab91757b47b6fdfceca7a7`

The tokenId of the star is in integer format: 
```
2.2011169051061497093684062886750321999196877802052952436800089787832045747112e+76
```	
and applying the value to the `tokenIdToStar` function, it succesfully returns the star.   


Star then is put for sale for 30000. Transaction hash is: `0x5ec7815630081f477df12c3eec44e7a45fea38618438215c511ccf6042e5ccca`


## Modify client code to interact with a smart contract
The index.html is modified to claim a star and get star info. The second function tokenIdToStarInfo() is working properly and for the tokenId mentioned before it returns:
```
Star Info:
Dimi Star,My great star,dec_14.53,mag_18.21,cent_19.40 

Star Owner:
0xefa409f8db2dca2d0d8838ab72cba15ffc4e4026
```

The createStar at the moment is not working through the interface. The account is not passed properly, so the error is identified there.  



## References
https://forum.ethereum.org/discussion/1995/iterating-mapping-types

https://medium.com/@alexpanas/udacity-blockchain-nanodegree-creating-unique-metadata-with-solidity-daccded333ef
