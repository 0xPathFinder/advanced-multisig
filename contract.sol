//SPDX-License-Identifier: MIT 
pragma solidity 0.8.0; 
 
contract Multisig{ 
 
    address public admin; 
 
    uint public requiredConfirmations;  
 
    uint public ownerSize; // remove public 
 
    address public second; // remove public 
 
    mapping(address => bool) public isOwner; 
    mapping(address => bool) public isConfirmedBy; 
    mapping(uint => uint) public currentNumConfirmations; 
 
    //mapping(uint => uint) public currentNumConfirmation; // txID => numberOfConfirmations 
 
    mapping(uint => Transactions) public executedTransactions; 
 
    event Deposit(address indexed _from, uint indexed _value, uint indexed _at); 
    event Confirmed(address indexed _from); // event to confirm() 
    event Revoked(address indexed _from); 
    event Withdrawn(address indexed _to, uint indexed _value, uint indexed _at); 
 
    struct Transactions { 
        address to; 
        uint amount; 
  uint time; 
    } 
 
    modifier onlyAdmin() { 
        require(msg.sender == admin, "Not Admin"); 
        _; 
    } 
 
    modifier ownersORadmin(address _owner) { 
        require(isOwner[_owner] || msg.sender == admin, "Address is not owner nor admin"); 
        _; 
    } 
 
    constructor(address _owner) { 
        require(msg.sender != _owner, "Cannot be the same"); 
        admin = msg.sender; 
        second = _owner; 
        isOwner[_owner] = true; 
 
        requiredConfirmations = 2; 
        ownerSize = 2; // initial size of owners is 2 (admin + second declared on constructor) 
 //  numConfirmations = _numConfirmations; // anyway 2 
    //     require(numConfirmations >= 2 && numConfirmations <= ownerSize, "Number of confirmations should be between two and number of owners"); 
    } 
 
    function changeNumConfirmations(uint _requiredConfirmations) public onlyAdmin { 
        require(_requiredConfirmations != requiredConfirmations, "Already that number of confirmations"); 
        requiredConfirmations = _requiredConfirmations; 
        require(requiredConfirmations >= 2 && requiredConfirmations <= ownerSize, "Number of confirmations should be between two and number of owners"); 
    } 
 
    function addOwner(address _owner) public onlyAdmin { 
        require(!isOwner[_owner], "Owner already exist"); 
        require(ownerSize <= 9, "The maximum number of owners is nine"); 
        isOwner[_owner] = true; 
        ownerSize++; 
    } 
 
    function removeOwner(address _owner) public onlyAdmin { 
        require(_owner != second, "This address cannot be removed"); 
        require(isOwner[_owner], "Owner not exist"); // true on isOwner 
        isOwner[_owner] = false; 
        ownerSize--; 
         
        // numConfirmations became ownerSize when one owner is removed for security reasons 
        requiredConfirmations = ownerSize; 
    } 
 
    function getBalance() public view returns(uint) { 
        return address(this).balance; 
    } 
 
// add transaction id with struct and return id then 
// add confirmations[txID]++; 
 
/////////////////////////////////// 
    // function confirm(address _to, uint _amount) public ownersORadmin(msg.sender) returns(uint) { 
    //     isConfirmedBy[msg.sender] = true; 
         
 //  uint txID = uint(keccak256(abi.encodePacked(_to, _amount, block.timestamp))); // 
   
 //  currentNumConfirmation[txID]++; 
 //  return txID; 
    // } 
 
 // function revokeConfirmation() public { 
   
 // } 
 
    // function withdrawn(uint _txID, address _to, uint _amount) public payable { 
    //     require(isConfirmedBy[admin], "Not confirmed by admin yet"); 
 //  //require(currentNumConfirmation[_txID] == numConfirmations, "Not the required number of confirmations"); 
   
 //   transaction[currentNumConfirmation[_txID]] = Transaction( 
 //   { 
 //    to: _to, 
 //    amount: _amount, 
 //    time: block.timestamp 
 //   } 
 //  ); 
    // } 
 
    function createTxID() public view onlyAdmin returns(uint) { 
        uint txID = uint(keccak256(abi.encodePacked(block.timestamp))); 
        return txID; 
    } 
 
    function confirm(uint _txID) public ownersORadmin(msg.sender)
{ 
        require(!isConfirmedBy[msg.sender],"Already confirmed"); 
        isConfirmedBy[msg.sender] = true; 
        currentNumConfirmations[_txID]++; 
 
        emit Confirmed(msg.sender); 
    } 
 
    function revoke(uint _txID) public ownersORadmin(msg.sender) { 
        require(isConfirmedBy[msg.sender], "Not confirmed yet"); 
        isConfirmedBy[msg.sender] = false; 
        currentNumConfirmations[_txID]--; 
 
        emit Revoked(msg.sender); 
    } 
 
    function withdrawn(uint _txID, address _to, uint _amount) public payable onlyAdmin { 
        require(currentNumConfirmations[_txID] == requiredConfirmations, "Not the required number of confirmations"); 
 
        (bool success, ) = _to.call{value: _amount}(""); 
        require(success, "Transaction execution failed"); 
 
        executedTransactions[_txID] = Transactions( 
            { 
                to: _to, 
                amount: _amount, 
                time: block.timestamp 
            } 
        ); 
 
        emit Withdrawn(_to, _amount, block.timestamp); 
    } 
 
    receive() external payable { 
        emit Deposit(msg.sender, msg.value, block.timestamp); 
    } 
 
} 
