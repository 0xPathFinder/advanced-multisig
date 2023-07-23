//SPDX-License-Identifier: MIT 
pragma solidity 0.8.0; 
 
contract Multisig{ 

    uint public requiredConfirmations;
    address admin;
    uint txID;
    uint ownerSize;
    uint numOfAddresses;
    address second;
    bool isCreateTxIdCalled;
    address[] addresses;

    mapping(address => bool) public isOwner; 
    mapping(address => bool) public isConfirmedBy; 
    mapping(uint => uint) public currentNumConfirmations; 
    mapping(uint => Transactions) public executedTransactions; 
 
    event Deposit(address indexed _from, uint indexed _value, uint indexed _at); 
    event Confirmed(address indexed _from);
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
    } 
 
    function changeNumConfirmations(uint _requiredConfirmations) external onlyAdmin { 
        require(_requiredConfirmations != requiredConfirmations, "Already that number of confirmations"); 
        requiredConfirmations = _requiredConfirmations; 
        require(requiredConfirmations >= 2 && requiredConfirmations <= ownerSize, "Number of confirmations should be between two and number of owners"); 
    } 
 
    function addOwner(address _owner) external onlyAdmin {
        require(!isOwner[_owner], "Owner already exist");
        require(ownerSize <= 9, "The maximum number of owners is nine");
        isOwner[_owner] = true;
        addresses.push(_owner);
        numOfAddresses++;
        ownerSize++;
    }
 
    function removeOwner(address _owner) external onlyAdmin {
        require(_owner != second, "This address cannot be removed");
        require(isOwner[_owner], "Owner not exist");
        isOwner[_owner] = false;
        for(uint i = 0; i < numOfAddresses; i++){
            
        }

        numOfAddresses--;
        ownerSize--;
         
        requiredConfirmations = ownerSize; 
    } 
 
    function getBalance() external view returns(uint) { 
        return address(this).balance;
    }

    function createTxID() external onlyAdmin returns(uint) {
        require(!isCreateTxIdCalled, "Only one txID can be created");
        txID = uint(keccak256(abi.encodePacked(block.timestamp)));
        isCreateTxIdCalled = true;
        return txID;
    }

    function confirm() external ownersORadmin(msg.sender) { 
        require(!isConfirmedBy[msg.sender],"Already confirmed");
        require(isCreateTxIdCalled == true, "Cannot be called without 'createTxID' at first");
        isConfirmedBy[msg.sender] = true;
        currentNumConfirmations[txID]++;
 
        emit Confirmed(msg.sender); 
    } 

    function revoke() external ownersORadmin(msg.sender) { 
        require(isConfirmedBy[msg.sender], "Not confirmed yet"); 
        isConfirmedBy[msg.sender] = false; 
        currentNumConfirmations[txID]--; 

        emit Revoked(msg.sender);
    }

    // need to find a way for isConfirmedBy and currentNumConfirmations resetting
    function withdrawn(address _to, uint _amount) external payable onlyAdmin { 
        require(currentNumConfirmations[txID] == requiredConfirmations, "Not the required number of confirmations"); 
 
        (bool success, ) = _to.call{value: _amount}(""); 
        require(success, "Transaction execution failed");
 
        executedTransactions[txID] = Transactions( 
            { 
                to: _to, 
                amount: _amount, 
                time: block.timestamp 
            }
        );

        isCreateTxIdCalled = false;
        currentNumConfirmations[txID] = 0;
        isConfirmedBy[admin] = false;
        isConfirmedBy[second] = false;

       for(uint i = 0; i < numOfAddresses; i++){
            isConfirmedBy[addresses[i]] = false;
        }

        numOfAddresses = 0;

        emit Withdrawn(_to, _amount, block.timestamp); 
    } 

    receive() external payable { 
        emit Deposit(msg.sender, msg.value, block.timestamp); 
    }

}
