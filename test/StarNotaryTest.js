const StarNotary = artifacts.require('StarNotary')

contract('StarNotary', accounts => { 
    beforeEach(async function() { 
        this.contract = await StarNotary.new({from: accounts[0]})
    })
    
    describe('Star test', () => { 
        
        it('can create a star and get its name', async function () { 
            await this.contract.createStar('awesome star1', 'Story', '3.5', '1.6', '2.3', 1, {from: accounts[0]})
            var readStar = await this.contract.tokenIdToStar(1)
            assert.equal(readStar[0], 'awesome star1')
            assert.equal(readStar[2], '3.5')
        })

        it('check if star exists', async function () { 
            await this.contract.createStar('awesome star1', 'Story', '3.5', '1.6', '2.3', 1, {from: accounts[0]})
            await this.contract.createStar('awesome star2', 'Story', '3.5', '1.6', '2.1', 2, {from: accounts[0]})
            await expectThrow(this.contract.createStar("awesome star3", "Story", "3.5", "1.6", "2.1", 3, {from: accounts[0]}))
        })

        it('token Id to star info', async function () { 
            await this.contract.createStar('awesome star1', 'Story', '3.5', '-1.6', '-2.3', 1, {from: accounts[0]})
            await this.contract.createStar('Star power 103!', 'I love my wonderful star', '032.155', '121.874', '245.978', 2, {from: accounts[0]})
            
            _star = await this.contract.tokenIdToStarInfo(2)

            assert.equal(_star[0], 'Star power 103!')
            assert.equal(_star[1], 'I love my wonderful star')
            assert.equal(_star[2], 'ra_032.155')
            assert.equal(_star[3], 'dec_121.874')
            assert.equal(_star[4], 'mag_245.978')           
        })

    })

    describe('Buying and selling stars tests', () => { 
        let user1 = accounts[1]
        let user2 = accounts[2]
        let approver = accounts[3]
        let randomMaliciousUser = accounts[3]

        let starId = 7
        let starId2 = 8
        let starId3 = 21
        let starId4 = 22

        let starPrice = web3.toWei(.01, "ether")

        beforeEach(async function () { 
            await this.contract.createStar('awesome star1', 'Story', '3.5', '1.6', '2.3', starId, {from: user1})    
            await this.contract.createStar('awesome star2', 'Story2', '13.5', '1.6', '2.3', starId2, {from: user1})    
            await this.contract.createStar('awesome star3', 'Story2', '13.5', '1.26', '2.3', starId3, {from: user1})    
            await this.contract.createStar('awesome star4', 'Story2', '13.5', '1.36', '2.3', starId4, {from: user1})    

        })

        it('user1 can put up their star for sale', async function () { 
            assert.equal(await this.contract.ownerOf(starId), user1)
            await this.contract.putStarUpForSale(starId, starPrice, {from: user1})
            assert.equal(await this.contract.starsForSale(starId), starPrice)
        })

        describe('user2 can buy a star that was put up for sale', () => { 
            beforeEach(async function () { 
                await this.contract.putStarUpForSale(starId, starPrice, {from: user1})
            })

            it('user2 is the owner of the star after they buy it', async function() { 
                await this.contract.buyStar(starId, {from: user2, value: starPrice, gasPrice: 0})
                assert.equal(await this.contract.ownerOf(starId), user2)
            })

            it('user2 ether balance changed correctly', async function () { 
                let overpaidAmount = web3.toWei(.05, 'ether')
                const balanceBeforeTransaction = web3.eth.getBalance(user2)
                await this.contract.buyStar(starId, {from: user2, value: overpaidAmount, gasPrice: 0})
                const balanceAfterTransaction = web3.eth.getBalance(user2)
                assert.equal(balanceBeforeTransaction.sub(balanceAfterTransaction), starPrice)
            })
            it('another user cannot buy the star from the new owner', async function() { 
                await this.contract.buyStar(starId, {from: user2, value: starPrice, gasPrice: 0})
                assert.equal(await this.contract.ownerOf(starId), user2)
                await expectThrow(this.contract.buyStar(starId, {from: randomMaliciousUser, value: starPrice, gasPrice: 0}))

            })
        })

        describe('sell a star through an approved user', () => {
            it('user1 approves approver for star2', async function(){
                await this.contract.approve(approver, starId2,{from: user1})
                assert(await this.contract.getApproved(starId2) == approver)
            })

            it('approver puts star2 to sale and user2 buys', async function(){
                await this.contract.approve(approver, starId2,{from: user1})
                assert(await this.contract.getApproved(starId2) == approver)
                await this.contract.putStarUpForSale(starId2, starPrice, {from: approver})
                await this.contract.buyStar(starId2,  {from: user2, value: starPrice, gasPrice: 0})
                assert.equal(await this.contract.ownerOf(starId2), user2)
            })
            it('sell two stars with setApproveForAll function', async function(){
                await this.contract.setApprovalForAll(approver, true, {from: user1})
                await this.contract.putStarUpForSale(starId3, starPrice, {from: approver})
                await this.contract.putStarUpForSale(starId4, starPrice, {from: approver})
                await this.contract.buyStar(starId3,  {from: user2, value: starPrice, gasPrice: 0})
                await this.contract.buyStar(starId4,  {from: user2, value: starPrice, gasPrice: 0})            
                assert.equal(await this.contract.ownerOf(starId3), user2)
                assert.equal(await this.contract.ownerOf(starId4), user2)
            })
            it('get correctly the tokenIds of the stars to sale', async function(){

                console.log(await this.contract.starsForSale({from:user1}))


            })
        })
    })
})


var expectThrow = async function(promise) { 
    try { 
        await promise
    } catch (error) { 
        assert.exists(error)
        return
    }

    assert.fail('Expected an error but didnt see one!')
}