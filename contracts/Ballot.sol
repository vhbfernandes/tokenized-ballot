// SPDX-License-Identifier: MIT


pragma solidity ^0.8.3;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Proposal.sol";
import "./VoteCoin.sol";


contract Ballot is Ownable {
   
    struct Voter {
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        bool voted;
    }

    VoteCoin public voteCoin;

    address public chairperson;

    mapping(address => Voter) public voters;

    //mapping(address => Proposal) proposalStructs;


    address[] public proposals;

    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(string memory name, string memory symbol, bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voteCoin = new VoteCoin(name, symbol);
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(address(new Proposal(proposalNames[i])));
        }
    }
    
    function getVoterBalance(address voter) public view virtual returns (uint256){
        return voteCoin.balanceOf(voter);
    }

    /** 
     * @dev Give 'voter' the right to vote on this ballot AKA receives 1 votecoin. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public onlyOwner {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require (voteCoin.balanceOf(voter) == 0);
        voteCoin.mint(voter, 1);
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            voteCoin.transfer(proposals[delegate_.vote], voteCoin.balanceOf(msg.sender));
        } else {
            voteCoin.transfer(to, voteCoin.balanceOf(msg.sender));
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(voteCoin.balanceOf(msg.sender) != 0, "Has no tokens to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        voteCoin.transfer(proposals[proposal], voteCoin.balanceOf(msg.sender));
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (address winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (voteCoin.balanceOf(proposals[p]) > winningVoteCount) {
                winningVoteCount = voteCoin.balanceOf(proposals[p]);
                winningProposal_ = proposals[p];
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = Proposal(winningProposal()).name();
    }
}
