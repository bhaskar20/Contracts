//@notice : blind auction contract
//@warning : this is not to be used in production

//@info : During the bidding period, a bidder does not actually send her bid, 
//but only a hashed version of it. Since it is currently considered practically
//impossible to find two (sufficiently long) values whose hash values are equal,
//the bidder commits to the bid by that. After the end of the bidding period,
//the bidders have to reveal their bids: They send their values unencrypted and
//the contract checks that the hash value is the same as the one provided during 
//the bidding period.

// Another challenge is how to make the auction binding and blind at the same time:
//The only way to prevent the bidder from just not sending the money after he won the
//auction is to make her send it together with the bid. Since value transfers cannot be
//blinded in Ethereum, anyone can see the value.

// The following contract solves this problem by accepting any value that is at least as
//large as the bid. Since this can of course only be checked during the reveal phase, some
//bids might be invalid, and this is on purpose (it even provides an explicit flag to place
//invalid bids with high value transfers): Bidders can confuse competition by placing several
//high or low invalid bids.



// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address public beneficiary;
    uint public auctionStart;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping (address => bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    mapping (address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    modifier onlyBefore(uint _time) { if (now >= _time) throw; _ }
    modifier onlyAfter(uint _time) { if (now <= _time) throw; _ }

    function BlindAuction(uint _biddingTime, uint _revealTime, address _beneficiary) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /// Place a blinded bid with `_blindedBid` = sha3(value,
    /// fake, secret).
    /// The sent ether is only refunded if the bid is correctly
    /// revealed in the revealing phase. The bid is valid if the
    /// ether sent together with the bid is at least "value" and
    /// "fake" is not true. Setting "fake" to true and sending
    /// not the exact amount are ways to hide the real bid but
    /// still make the required deposit. The same address can
    /// place multiple bids.
    function bid(bytes32 _blindedBid) onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid : _blindedBid,
            deposit : msg.value
        }));
    }
    /// Reveal your blinded bids. You will get a refund for all
    /// correctly blinded invalid bids and for all bids except for
    /// the totally highest.
    function reveal(uint[] _values, bool[] _fake, bytes32[] _secret) onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint length = bids[msg.sender].length;
        if (_values.length != length) || _fake.length != length || _secret.length != length){
            //do nothing
        } else {
            throw;
        }
        uint refund;
        for (uint i=0 ; i< length ; i++){
            var bid = bids[msg.sender][i];
            var (value, fake, secret) = (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid != sha3(value, fake, secret)){
                //bid was incorrect
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value){
                if(placeBid(msg.sender, value)){
                    refund -= value;
                }
            }
            bid.blindedBid = 0;
        }
        if (!msg.sender.send(refund)){
            throw;
        }
    }

    function placeBid(address bidder, uint value) internal returns (bool success) { 
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// Withdraw a bid that was overbid.
    function withdraw() {
        var amt = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        if (!msg.sender.send(amount)) {
            throw;
        }
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() onlyAfter(revealEnd) {
        if (ended)
            throw;
        AuctionEnded(highestBidder, highestBid);
        ended = true;
        if (!beneficiary.send(this.balance))
            throw;
    }

    function () {
        throw;
    }   
}