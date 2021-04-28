pragma solidity ^0.8.0;

contract Stokvel {
    Member[] public members;
    Cause[] public causes;
    
    uint public maxMemberLimit = 5;
    uint public totalMembers;
    uint public payeeIndex = 0;
    uint public startPayDate;

    address public chairperson;
    
    
    struct Member{
        address account;
        uint payDate;
        bool isInArrears;
        bool voted;
    }
    
    struct Cause{
        string name;
        uint voteCount;
    }
    
    constructor(
        uint _limit,
        uint _payDate,
        address[] memory _members,
        string[] memory _causes
        //uint _causeEndDate;
    ) public
    {
        chairperson = msg.sender;
        maxMemberLimit = _limit;
        startPayDate = block.timestamp;
        totalMembers = _members.length;
        
        for(uint i = 0; i < _members.length; i++){
            uint payDate = startPayDate + 5 * 1 minutes;
            members.push(Member(_members[i], payDate, true, false));
         }
       
        for(uint i = 0; i < _causes.length; i++){
            causes.push(Cause(_causes[i], 0));
        }
        
    }
    
    function payDues() public {
        require(msg.value == 1, "Only 1 ether must paid");
        require(members[msg.sender].isInArrears, "Member account is not in arrears");
        
        address(this).transfer(msg.value);
        members[msg.sender].isInArrears = false;
        
    }
    
    function register(address newMember) public {
         require(msg.value == 1, "Only 1 ether must paid");
        
        totalMembers++;
        if(totalMembers > maxMemberLimit){
            revert();
        }
        
        uint memberPayDate = members[members.length - 1].payDate + 5 * 1 minutes;
        members.push(Member(address(msg.sender), memberPayDate, false, false));
    }
}