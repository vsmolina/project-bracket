// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./IOracle.sol";


contract Oracle is Ownable, IOracle {
    
    using DateTime for uint;
    
    mapping(bytes32 => uint) matchIdToIndex;
    mapping(string => bytes32) eventnameToId;
    
    
    
    struct Match {
        bytes32 id;
        bytes32 eventId;
        string party1;
        string party2;
        uint participantCount;
        uint date;
        uint time;
        MatchOutcome outcome;
        int winner;
    }
    
    Match[] matches;
    //Match[] tourneyMatches;
    
    function createEventID(string memory _eventname) public returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(_eventname));
        
        eventnameToId[_eventname] = id;
        return id;
    }
    
    function _getMatchIndex(bytes32 _matchId) private view returns (uint) {
        return matchIdToIndex[_matchId] - 1;
    }
    
    function getEventId(string memory _eventname) public view returns (bytes32) {
        return eventnameToId[_eventname];
    }
    
    function matchExists(bytes32 _matchId) public override returns (bool) {
        if (matches.length == 0) {
            return false;
        }
        uint index = matchIdToIndex[_matchId];
        return (index > 0);
    }
    
    function eventExists(string memory _eventname) public view returns (bool) {
        if (matches.length == 0) {
            return false;
        }
        bytes32 index = eventnameToId[_eventname];
        return (index > 0);
    }
    
    function addMatch(bytes32 _eventId, string memory _party1, string memory _party2, uint _participantCount, uint _date, uint _time) public override onlyOwner returns (bytes32) {
        
        bytes32 id = keccak256(abi.encodePacked(_eventId, _party1, _party2, _participantCount, _date, _time));
        
        require(!matchExists(id));
        
        matches.push(Match(id, _eventId, _party1, _party2, _participantCount,_date, _time, MatchOutcome.pending, -1));
        matchIdToIndex[id] = matches.length - 1;
        
        return id;
    }
    
    function setMatchUnderway(bytes32 _matchId) override external onlyOwner {
        
        require(matchExists(_matchId));
        
        uint index = _getMatchIndex(_matchId);
        Match storage theMatch = matches[index];
        
        require(theMatch.outcome == MatchOutcome.pending);
        
        theMatch.outcome = MatchOutcome.underway;
    }
    
    
    function setMatchCancelled(bytes32 _matchId) override external onlyOwner {
        
        require(matchExists(_matchId)); 
        
        uint index = _getMatchIndex(_matchId);
        Match storage theMatch = matches[index]; 
        
        require(theMatch.outcome == MatchOutcome.pending); 
        
        theMatch.outcome = MatchOutcome.cancelled;
    }
    
    function declareOutcome(bytes32 _matchId, MatchOutcome _outcome, int _winner) override onlyOwner external {

        require(matchExists(_matchId)); 

        uint index = _getMatchIndex(_matchId);
        Match storage theMatch = matches[index]; 

        require(theMatch.outcome == MatchOutcome.underway); 

        if (_outcome == MatchOutcome.decided) 
            require(_winner >= 0); 

        theMatch.outcome = _outcome;
        
        if (_outcome == MatchOutcome.decided) 
            theMatch.winner = _winner;
    }
    
    function getPendingMatches() public override returns (bytes32[] memory) {
        uint count = 0; 

        //get count of pending matches 
        for (uint i = 0; i < matches.length; i++) {
            if (matches[i].outcome == MatchOutcome.pending) 
                count++; 
        }

        //collect up all the pending matches
        bytes32[] memory output = new bytes32[](count); 

        if (count > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                if (matches[n-1].outcome == MatchOutcome.pending) 
                    output[index++] = matches[n-1].id;
            }
        } 

        return output; 
    }
    
    function getAllMatches() public override returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](matches.length);
        
        if (matches.length > 0) {
            uint index = 0;
            for (uint i = matches.length; i > 0; i--) {
                output[index++] = matches[i-1].id;
            }
        }
        
        return output;
    }
    
    function getMatch(bytes32 _matchId) public override returns (
        bytes32 id,
        bytes32 eventId, 
        string memory party1,
        string memory party2,
        uint participantCount,
        uint date,
        uint time,
        MatchOutcome outcome, 
        int winner) {
        
        //get the match 
        if (matchExists(_matchId)) {
            Match storage theMatch = matches[_getMatchIndex(_matchId)];
            return (theMatch.id, theMatch.eventId, theMatch.party1, theMatch.party2, theMatch.participantCount, theMatch.date, theMatch.time, theMatch.outcome, theMatch.winner); 
        }
        else {
            return (_matchId, "", "", "", 0, 0, 0, MatchOutcome.pending, -1); 
        }
    }
    
    function getMostRecentMatch(bool _pending) public override returns (
        bytes32 id,
        bytes32 eventId, 
        string memory party1,
        string memory party2,
        uint participantCount,
        uint date,
        uint time,
        MatchOutcome outcome, 
        int winner) {

        bytes32 matchId = 0; 
        bytes32[] memory ids;

        if (_pending) {
            ids = getPendingMatches(); 
        } else {
            ids = getAllMatches();
        }
        if (ids.length > 0) {
            matchId = ids[0]; 
        }
        
        return getMatch(matchId); 
    }
    
    // separate the matches by eventID
    function eventMatches(bytes32 _eventId) public view returns (Match[] memory) {
        //require(eventExists(_eventId));
        
        uint count = 0; 
        
        //get count of matches in the event 
        for (uint i = 0; i < matches.length; i++) {
            if (matches[i].eventId == _eventId) 
                count++; 
        }

        //collect up all events matches
        Match[] memory output = new Match[](count); 

        if (count > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                if (matches[n-1].eventId == _eventId) {
                    output[index++] = matches[n-1];
                }
            }        
        }
        
        // return an array containing the matches of an event
        return output; 
    }
    
    function getEventPlayers(bytes32 _eventId) public view returns (string[] memory) {
        Match[] memory input = eventMatches(_eventId);
        string[] memory output = new string[](2 * (input.length));
        
        for (uint i = 0; i < (2 * (input.length)); i+2) {
            output[i] = input[i].party1;
            output[i+1] = input[i].party2;
        }
        
        return output;
    }
    
    function testConnection() public override returns (bool) {
        return true; 
    }
    
    function getAddress() public view returns (address) {
        return address(this);
    }
}