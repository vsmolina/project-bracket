// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

abstract contract IOracle {

    enum MatchOutcome {
        pending,    //match has not been fought to decision
        underway,   //match has started & is underway
        draw,       //anything other than a clear winner (e.g. cancelled)
        decided,    //index of participant who is the winner
        cancelled   //match was cancelled; there's no winner 
    }

    function getPendingMatches() public virtual returns (bytes32[] memory);

    function getAllMatches() public virtual returns (bytes32[] memory);

    function matchExists(bytes32 _matchId) public virtual returns (bool); 
    
    //function eventExists(bytes32 _eventId) public returns (bool);

    function addMatch(bytes32 _eventId, string memory _party1, string memory _party2, uint _participantCount, uint _date, uint _time) public virtual returns (bytes32);

    function setMatchUnderway(bytes32 _matchId) virtual external; 

    function setMatchCancelled(bytes32 _matchId) virtual external; 

    function declareOutcome(bytes32 _matchId, MatchOutcome _outcome, int _winner) virtual external; 

    function getMatch(bytes32 _matchId) public virtual returns (
        bytes32 id,
        bytes32 eventId, 
        string memory party1,
        string memory party2,
        uint participantCount,
        uint date,
        uint time,
        MatchOutcome outcome, 
        int winner);

    function getMostRecentMatch(bool _pending) public virtual returns (
        bytes32 id,
        bytes32 eventId, 
        string memory party1,
        string memory party2,
        uint participantCount,
        uint date,
        uint time,
        MatchOutcome outcome, 
        int winner);
    
    //function eventMatches(bytes32 _eventId) public returns (bytes32[]);

    function testConnection() public virtual returns (bool);
}