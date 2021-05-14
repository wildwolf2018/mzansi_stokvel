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
    bool public hasDonated = false;

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
        address payable account;
    }
    
    event Payment(address _payer, uint amountOwed);
    event VoteCast(address voter, string causeName);
    event MemberPaid(address beneficiary, uint payment);
    event DonationMade(string causeName, address causeAccount, uint donation);
    
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
    
    function payDues() public payable {
      require(msg.value == 2 ether && members[msg.sender].payDate != 0);
      if(members[msg.sender].isInArrears){
          members[msg.sender].isInArrears = false;
          payable(address (this)).transfer(msg.value);
	  totalFunds = address(this).balance;
	  emit Payment(msg.sender, msg.value);
      }
   }
   
    function payMember() public payable {
      require(msg.sender == chairperson, "Only chairperson authorised to make payements");
   
      payeeIndex = nextPayee();
      if(hasFunds()){
        address payable beneficiary = accounts[payeeIndex];

        if(!members[beneficiary].isPaid && !members[beneficiary].isInArrears){
	  members[beneficiary].isPaid = true;
	  members[beneficiary].isInArrears = true;    

	  uint payment = totalMembers * 1 ether;
	  assert(payment < address(this).balance);
	  totalFunds = address(this).balance - payment;
	  beneficiary.transfer(payment);
	  emit MemberPaid(beneficiary, payment);

	  if(payeeIndex >= accounts.length - 1){
	    reset();
	  }
        }
     }
    }
    
  function reset() private{
     if(payeeIndex >= accounts.length - 1){
       payeeIndex = 0;
       uint lasyPayDate = members[accounts[accounts.length-1]].payDate;
       for(uint i = 0; i < accounts.length; i++){
           members[accounts[i]].isPaid = false;
           members[accounts[i]].payDate = lasyPayDate + (i+1) * 1 minutes;
       }
     }
  }
  
  function nextPayee() private view returns(uint){
      address prevPayee;
      for(uint i = 0; i < accounts.length; i++){
         if(i == 0){
             prevPayee = accounts[accounts.length-1];
         }else{
	     prevPayee = accounts[i-1];
         }
           
         address beneficiary = accounts[i];
         if(block.timestamp > members[prevPayee].payDate && block.timestamp <= members[beneficiary].payDate){
            return i;   
         }
     }
     return 0;
  }
  
 function vote(address voter, uint _causeIndex) public{
   require(members[voter].payDate != 0, "Only members can vote");
   require(!members[voter].voted && (_causeIndex >= 0 && _causeIndex < causes.length));
       
   if(block.timestamp <= donationDate){
      causes[_causeIndex].voteCount = causes[_causeIndex].voteCount + 1;
      members[voter].voted = true;
      emit VoteCast(voter, causes[_causeIndex].name);
   }
 }

 function payCharity() public payable {
      require(msg.sender == chairperson, "Only chairperson can make donation");
      require(block.timestamp > donationDate, "Donation date has not yet passed");
      
      uint donation = address(this).balance / 20;
      if(!hasDonated && address(this).balance > donation){
          hasDonated = true;
          uint maxVotesIndex = 0;
          uint maxVotes = causes[0].voteCount;
           
          for(uint i = 0; i < causes.length; i++){
	    if(causes[i].voteCount > maxVotes){
                maxVotesIndex = i;
            }
          }
           
          assert(address(this).balance > donation);
          totalFunds = address(this).balance + donation;
          causes[maxVotesIndex].account.transfer(donation);
          emit DonationMade(causes[maxVotesIndex].name, causes[maxVotesIndex].account, donation);
      }
  }
  
  function hasFunds() private returns(bool) {
      uint minBalance = totalMembers * 1 ether;
      if(payeeIndex == 0 && (address(this).balance < totalMembers * minBalance)){
          uint startTime = block.timestamp;
          
          for(uint i = 0; i < accounts.length; i++){
            members[accounts[i]].payDate = startTime + (i + 1) * 1 minutes;
         }
         return false;
      }
      return true;
  }

}
