//@notice : vote ballot where voter can delegate his/her vote to other party
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

contract Ballot {
    //@notice : struct to hold voters info
    struct Voter {
        uint weigth;
        bool voted;
        address delegate;
        uint vote;
    }

    //@notice : struct to hold various proposals where user can vote

    struct Proposal {
        bytes32 name; //name upto 32 bytes only
        uint voteCount;
    }

    address public chairperson;
    //@notice : mapping to store voter address
    mapping (address=>Voter) voters;
    //@notice : dynamic array to store proposals
    Proposal[] public proposals;

    function Ballot(bytes32[] proposalName) {
        chairperson = msg.sender;
        voters[chairperson].weigth = 1;

        //@notice : for each provided proposal,
        // create a new proposal object and add it 
        // to the end of array
        //@warning : there should be a overflow check for proposalName length
        for (uint i = 0 ; i < proposalName.length ; i++){
            proposals.push(Proposal({
                name : proposalName[i];
                voteCount : 0;
            }))
        }
    }

    //@notice : only chaiman access
    modifier onlyChairperson() {
        if (msg.sender != chairperson) throw;
        _
    }

    //@notice : chairman can give voting right to any voter
    function giveRightToVote(address voter) onlyChairperson {
        if (voters[voter].voted) throw;
        voters[voter].weigth = 1;
    }

    //@notice : voter can delegate his/her vote to some other voter
    function delegate(address to) {
        if (!voters[msg.sender]) throw;
        if (voters[msg.sender].voted) throw;
        if (to == msg.sender) throw;
        if (!voter[to]) throw;

        voter[msg.sender].voted = true;
        voter[msg.sender].delegate = to;
        
        //check if delegate already voted;
        if (voter[to].voted) {
            proposals[delegate.vote].voteCount += voter[msg.sender].weigth;
        } else {
            voter[to].weigth += voter[msg.sender];
        }
    }

    //@notice : voting by users
    function vote(uint proposal) {
        if (proposal <= proposals.length) throw; //overflow protection
        if (voters[msg.sender].voted) throw;

        voters[msg.sender].voted = true;
        voters[msg.sender].vote = proposal;

        proposals[proposal].voteCount += voter[msg.sender].weigth;
    }

    //@notice : compute winning proposal
    //@warning : no mechanism to know draws :P
    function winningProposal() constant returns(uint winningProposal) {
        uint winningVoteCount = 0;
        for (uint i = 0 ; i < proposals.length; i++){
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal = i;
            }
        }
    }
}