//@notice : simple auction where every party can see each others bids
//@warning : this is not to be used in production

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

contract OpenAuction {
    address public beneficiary;
    uint public auctionStart;
    uint public biddingTime;

    //@notice : state of auction
    address public highestBidder;
    uint public highestBid;
    enum status { Open, Closed};
    bytes32 status;

    //@notice : allowed withdrawls for bidders;
    mapping (address => uint) pendingReturns;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    modifier notClosed() {
        if (now > auctionStart + biddingTime || (status == Status.Closed)) throw;
        _
    }

    modifier 

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    function OpenAuction(uint _biddingTime, address _beneficiary) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
        status = Status.Open;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() notClosed {
        if (msg.value <= highestBid) {
            throw;
        }
        if (highestBidder != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }
    /// withdraw a bid which was overbid.
    function withdraw() {
        var amt = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        if (!msg.sender.send(amt)) throw;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd(type name) {
        if (now <= auctionStart + biddingTime) {
            throw;
        }
        if (status == Status.Closed) throw;
        status = Status.Closed;
        AuctionEnded(highestBidder, highestBid);

        if (!beneficiary.send(highestBid))
            throw;
    }

    function () {
        // This function gets executed if a
        // transaction with invalid data is sent to
        // the contract or just ether without data.
        // We revert the send so that no-one
        // accidentally loses money when using the
        // contract.
        throw;
    }


}