let statutaryRulesHash = "Hello World Rules";
let statutaryGoalsHash = "Hello World Goals";
let lastVote = 1533772800 // August 9 2018

let Master = artifacts.require("./Master.sol");

module.exports = function(deployer) {
  deployer.deploy(Master, statutaryGoalsHash, statutaryRulesHash, lastVote);
};
