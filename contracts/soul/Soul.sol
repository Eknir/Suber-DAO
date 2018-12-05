pragma solidity ^0.4.24;

contract Soul {

    bytes32 public myObjectives;
    bytes32 public myPrinciples;
    bytes32 public myRules;

    constructor(bytes32 _myObjectives, bytes32 _myPrinciples, bytes32 _myRules) {
        myObjectives = _myObjectives;
        myPrinciples = _myPrinciples;
        myRules = _myRules;
    }
}
