import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";
import { expect } from "chai";

const PROPOSALS = ["batata","queijo","bacon"]

describe("Ballot", function () {
  let accounts: Signer[];
  let contract: Contract;
  let ownerAddress: String;

  beforeEach(async function () {
    accounts = await ethers.getSigners();
    ownerAddress = await accounts[0].getAddress();
    const BallotContract: ContractFactory = await ethers.getContractFactory(
      "Ballot"
    );

    let proposalsbytes32: any[] = []
    let translatedArray: any[]
    PROPOSALS.forEach(function(text) {
      proposalsbytes32.push(ethers.utils.formatBytes32String(text))
    })

    contract = await BallotContract.deploy(proposalsbytes32);
    await contract.deployed();
  });

  it("Should deploy and set list of proposals", async function () {
    expect(ethers.utils.parseBytes32String((await contract.proposals(0)).name)).to.equal(PROPOSALS[0]);
  });

  it("Should create the chairperson as the contract owner", async function () {
    expect(await contract.chairperson()).to.be.equal(ownerAddress)
  })

  it("Should allow chairperson to give voting rights", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    expect((await contract.voters(accounts[1].getAddress())).weight).to.equal(1)
  });

  it("Should not allow user other than chairperson to give voting rights", async function () {
    expect(contract.connect(accounts[1]).giveRightToVote(accounts[1].getAddress())).to.be.revertedWith("Ownable: caller is not the owner")
  });

  it("Should allow user to vote on proposals after receiving rights", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    expect(await contract.connect(accounts[1]).vote(1)).to.be.ok //que
  });

  it("Should not allow user to vote on proposals without receiving rights to vote", async function () {
    expect(contract.connect(accounts[1]).vote(1)).to.be.revertedWith("Has no right to vote") //que
  });

  it("Should not allow user to receive voting rights after voting", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    await contract.connect(accounts[1]).vote(1)
    expect(contract.giveRightToVote(accounts[1].getAddress())).to.be.revertedWith("The voter already voted")
  });

  it("Should not allow user to vote twice", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    await contract.connect(accounts[1]).vote(1)
    expect(contract.connect(accounts[1]).vote(1)).to.be.revertedWith("Already voted.")
  });

  it("Should allow user to delegate voting rights", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    await contract.connect(accounts[1]).delegate(accounts[2].getAddress())
    expect(await contract.connect(accounts[2]).vote(1)).to.be.ok //que
  });

  it("Should not allow user to delegate voting rights after voting", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    await contract.connect(accounts[1]).vote(1)
    expect(contract.connect(accounts[1]).delegate(accounts[2].getAddress())).to.be.revertedWith("You already voted.")
  });

  it("Should not allow voter to delegate to himself", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    expect(contract.connect(accounts[1]).delegate(accounts[1].getAddress())).to.be.revertedWith("Self-delegation is disallowed.")
  });

  it("Should get winner after voting", async function () {
    await contract.giveRightToVote(accounts[1].getAddress())
    await contract.connect(accounts[1]).vote(0)
    expect(ethers.utils.parseBytes32String(await contract.winnerName())).to.equal(PROPOSALS[0])
  })
})