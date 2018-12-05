let globalVotingEngine;

//ERC20VoucherMintGuardian
let initialERC20Minters;
let initialERC20Mint;
let initialERC20MintBudgets;
let initialERC20MintBudgetPeriods;
let initialERC20MintMultipliers;
let ERC20MintGuardianVotingEngine = globalVotingEngine;

//ERC20Treasury
let initialERC20Spenders;
let initialERC20;
let initialERC20SpendBudgets;
let initialERC20SpendBudgetPeriods;
let initialERC20SpendMultipliers;
let ERC20TreasuryVotingEngine = globalVotingEngine;

// etherTreasury
let initialEtherSpenders; // array
let initialSpendBudgets; // array
let initialSpendBudgetPeriods; // array
let initialSpendMultipliers; // array
let etherTreasuryVotingEngine = globalVotingEngine;

// Slasher
let proposerSlash;
let voterSlash;
let nonVoterSlash;
let slasherWindow;
let voucherRegistry;
let slasherVotingEngine = globalVotingEngine;

//SoulChangable
let myObjectives;
let myPrinciples;
let myRules;
let soulVotingEngine = globalVotingEngine;

//TODO: make sure all addresses of contracts are passed last (consistency)
//TODO: update the paramers below to reflect the state in the smart-contract. 
//  referendumQuotum = 200000; // 20% (1,000,000 = 100%)
//  majorityQuotum = 600000; // 60%
//  assemblyInterval = 1576800; // 6 months
//  assemblyDuration = 122800; // 2 days TODO, see 6
//  votingWindow = 172800; // 2 days
//  revealOrCancelWindow = 86400; // 1 day
//  minimumVouchersToPropose = 0; // a treshhold which is needed to propose a vote during the assembly
//VotingEngineChangable
let referendumQuotum; //200000
let majorityQuotum; //600000
let assemblyInterval; //1576800
let assemblyDuration; //122800
let votingWindow; //172800
let revealOrCancelWindow; //86400
let minimumVouchersToPropose; //0
let voucherMintGuardian
let slasher
let etherTreasury
let erc20Treasury
let erc20MintTreasury
let voucherRegistry

//voucherRegistryChangable
// no constructor arguments

// vouhcerMintGuardianChangable
let votingEngine;
let initialMinters; //array
let initialBudgets; //array
let initialMintBudgetPeriods; //array
let initialMintSaveMultipliers; //array
let voucherRegistry;

let ERC20ERC20MintGuardianChangable = artifacts.require("./ERC20ERC20MintGuardianChangable.sol");
let ERC20TreasuryChangeable = artifacts.require()

module.exports = function(deployer) {
  deployer.deploy(Master, statutaryGoalsHash, statutaryRulesHash, lastVote);
};
