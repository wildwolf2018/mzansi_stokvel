pragma solidity ^0.8.0;

contract Stokvel {
    mapping(address => Member) members;
    address payable[] public accounts;
    Cause[] public causes;
    
    uint public totalMembers;
    uint public payeeIndex = 0;
    uint public creationDate;
    uint public totalFunds;
    uint public donationDate;

    address public chairperson;
    
    
    struct Member{
        uint payDate;
        bool isInArrears;
        bool isPaid;
        bool voted;
    }
    
    struct Cause{
        string name;
        uint voteCount;
        address account;
    }
    
    constructor(
        address payable[] memory  _accounts,
        string[] memory _causes,
        address payable[] memory _causeAccounts,
        uint _donationDate
       
    ) public
    {
        chairperson = msg.sender;
        creationDate = block.timestamp;
        totalMembers = _accounts.length;
        donationDate = _donationDate;
        
        for(uint i = 0; i < _accounts.length; i++){
            uint payDate = creationDate + (i + 1) * 1 minutes;
            members[_accounts[i]] = Member(payDate, true, false, false);
            accounts.push(_accounts[i]);
         }
       
        for(uint i = 0; i < _causes.length; i++){
            if(donationDate <= creationDate) {
                revert();
            }
            causes.push(Cause(_causes[i], 0, _causeAccounts[i]));
        }
        
        totalFunds = address(this).balance;
    }
    
	function payDues(address _payer) public payable {
      require(msg.value == 2 ether && members[_payer].payDate != 0);
      if(members[_payer].isInArrears){
          totalFunds = address(this).balance + msg.value;
          members[_payer].isInArrears = false;
          payable(address (this)).transfer(msg.value);
      }
  }
  
}