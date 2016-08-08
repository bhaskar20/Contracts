//@notice : contract to remote purchase a item
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

contract RemotePurchase {
    address public seller;
    uint public value;
    address public buyer;
    enum State {Created, Locked, Inactive};
    State public state;

    modifier onlyState(State _state) {
        if (state != _state){
            throw;
        } 
        _
    }
    modifier onlySeller() {
        if (msg.sender != seller){
            throw;
        }_
    }
    
    modifier onlyBuyer() {
        if (msg.sender != buyer){
            throw;
        }
        _
    }
    modifier require(bool _cond) {
        if (!_cond){
            throw;
        }
        _
    }
    function RemotePurchase() {
        seller = msg.sender;
        value = msg.value/2;
        state = State.Created;
        if (value*2 != msg.value){
            throw;
        }
    }
    event aborted();
    event purchaseConfirmed();
    event itemReceived();

    /// Seller can cancel the contract and redeem money stored before locking
    function abort() onlyState(State.Created) onlySeller  {
        aborted();
        state = State.Inactive;
        if (!seller.send(this.balance)){
            throw;
        }
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase() onlyState(State.Created) require(msg.value == 2*value) {
        buyer = msg.sender;
        purchaseConfirmed();
        state = State.Locked;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived() onlyBuyer onlyState(State.Locked) {
        itemReceived();
        state = State.Inactive;
        if (!buyer.send(value) || !seller.send(this.balance)){
            throw;
        }
    }
    function () {
        throw;
    }
}