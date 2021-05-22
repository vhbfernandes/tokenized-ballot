// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


interface IProposal {
	function act() pure external;
}

contract Proposal {
    bytes32 public _name;

     /** 
     * @dev Create a new proposal with a name.
     * @param proposalName name of proposal
     */
    constructor(bytes32 proposalName) {
        _name = proposalName;
    }

    function name() public view virtual returns (bytes32) {
        return _name;
    }

    function act () public pure returns(string memory) {
    	return "top";
    }
    
}