pragma solidity ^0.8.0;

contract Stokvel {
    mapping(address => Member) members;
    address payable[] public accounts;
    Cause[] public causes;
    
    uint public totalMembers;
    uint public payeeIndex = 0;
    uint public creationDate;
    uint public donationDate;
    bool public hasDonated = false;
    uint public lastPayDate;
    uint public contractBalance;
    uint public membershipFee = 2000000000000000000 wei;
    uint public paymentToMember;
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
        lastPayDate = creationDate;
	paymentToMember = totalMembers * 1 ether;
	
	if(donationDate <= creationDate) {
                revert();
        }
	
        for(uint i = 0; i < _accounts.length; i++){
            uint payDate = creationDate + (i + 1) * 14 days;
            members[_accounts[i]] = Member(payDate, true, false, false);
            accounts.push(_accounts[i]);
         }
       
        for(uint i = 0; i < _causes.length; i++){
            causes.push(Cause(_causes[i], 0, _causeAccounts[i]));
        }
    }
    
    function payDues(uint _membershipFee) public payable {
      address payee = msg.sender;
      require(msg.value == membershipFee && msg.value == _membershipFee, "You can only send 2 ether");
      require(members[payee].payDate != 0, "Only members can pay their dues");
      
      if(members[payee].isInArrears){
         members[payee].isInArrears = false;	 
	 emit Payment(payee, msg.value);
      }else{
        revert();
      }
      contractBalance = address(this).balance;
   }
   
    function payMember() public payable {
      require(msg.sender == chairperson, "Only chairperson authorised to make payements");
   
      payeeIndex = nextPayee();
      if(hasFunds()){
        address payable beneficiary = accounts[payeeIndex];

        if(!members[beneficiary].isPaid && !members[beneficiary].isInArrears){
	  members[beneficiary].isPaid = true;
	  members[beneficiary].isInArrears = true;    

	  assert(paymentToMember < address(this).balance);
	  lastPayDate = members[beneficiary].payDate;
	  
	  beneficiary.transfer(paymentToMember);
	  contractBalance = address(this).balance;
	  emit MemberPaid(beneficiary, paymentToMember);

	  if(payeeIndex >= accounts.length - 1){
	    reset();
	  }
       }
    }
  }
    
  function reset() private{
     if(payeeIndex >= 0 && payeeIndex < accounts.length){
       for(uint i = 0; i < accounts.length; i++){
           members[accounts[i]].isPaid = false;
           members[accounts[i]].payDate = lastPayDate + (i+1) * 14 days;
       }
     }
  }
  
  function nextPayee() private view returns(uint){
    for(uint i = 0; i < accounts.length; i++){
       address beneficiary = accounts[i];
       if(block.timestamp > lastPayDate && block.timestamp <= members[beneficiary].payDate){
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
           
          for(uint i = 1; i < causes.length; i++){
	    if(causes[i].voteCount > maxVotes){
                maxVotesIndex = i;
            }
          }
           
          assert(address(this).balance > donation);
          causes[maxVotesIndex].account.transfer(donation);
	  contractBalance = address(this).balance;
          emit DonationMade(causes[maxVotesIndex].name, causes[maxVotesIndex].account, donation);
      }
  }
  
  function hasFunds() private returns(bool) {
     if(payeeIndex == 0 && (address(this).balance < totalMembers * paymentToMember)){
        uint startTime = block.timestamp;
          
        for(uint i = 0; i < accounts.length; i++){
           members[accounts[i]].payDate = startTime + (i + 1) * 14 days;
        }
        return false;
     }
     return true;
  }
  
  function getNumberOfCauses() public view returns(uint){
      return causes.length;
  }

  function getCauseName(uint index) public returns(string memory){
      return causes[index].name;
  }

}
