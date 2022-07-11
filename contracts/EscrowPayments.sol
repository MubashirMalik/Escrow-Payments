// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;
pragma experimental ABIEncoderV2; //Hint (or distraction): Allows returning arrays from functions

contract EscrowPayments {
  address payable public owner;
  address public ttp;
  bool isTtpSet;
  event debugLog(uint index);

  struct Item {
    string title;
    uint price;
    bytes1 status;
    address payable buyer;
  }
  Item[] public items;

  constructor() {
    owner = payable(msg.sender);
    isTtpSet = false;
  }

  modifier onlyTtp {
    require(msg.sender == ttp);
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyOnce {
    require(isTtpSet == false);
    _;
  }

  modifier isValidItem(string memory title) {
    (uint i, bool isFound ) = searchItem(title);
    require(
      isFound == true, "Item not found."
    );
    _;
  }

  modifier isDisputed(string memory title) {
    (uint i, ) = searchItem(title);
    require(
      items[i].status == 'D', "Item is not disputed."
    );
    _;
  }

  modifier onlyBuyer(string memory title) {
    (uint i, bool isFound) = searchItem(title);

    require(
      isFound == true, "Item not found."
    );

    require(
      items[i].buyer == msg.sender, "Only the buyer can do this."
    );
    _;
  }

  modifier eitherOwnerOrBuyer(string memory title) {
    (uint i, bool isFound) = searchItem(title);
    require(
      msg.sender == owner || msg.sender == items[i].buyer,
      "Only Owner and Buyer can receive payments."
    );
    _;
  }



  function addItem(string memory title, uint price) public onlyOwner {
    items.push(Item(title, price, 'A', payable(0))); // available
  }

  function listItems() external view returns(Item[] memory) {
    return items;
  }

  function addTTP(address _ttp) public onlyOwner onlyOnce {
    ttp = _ttp;
    isTtpSet = true;
  }

  function searchItem(string memory title) internal view returns(uint, bool){
    bool isFound = false;
    uint i;
    for(i = 0; i < items.length; i++) {
      if( keccak256(abi.encodePacked(items[i].title)) == keccak256(abi.encodePacked(title))) {
        isFound = true;
        break;
      }
    }
    return (i, isFound);
  }

  function buyItem(string memory title) external payable isValidItem(title) {
    (uint i, ) = searchItem(title);
    require(
      msg.value >= 1000000000000000000* items[i].price, "You did not send enough ethers."
    );

    items[i].status = 'P'; // pending
    items[i].buyer = payable(msg.sender);
  }

  function confirmPurchase(string memory title, bool status) external onlyBuyer(title) isValidItem(title) {
    (uint i, ) = searchItem(title);
    if (status) {
      items[i].status = 'C'; // confirmed
    } else {
      items[i].status = 'D'; // disputed
    }
  }

  function handleDispute(string memory title, bytes1 status) external onlyTtp isDisputed(title) isValidItem(title) {
    (uint i, ) = searchItem(title);
    items[i].status = status;
  }

  function receivePayment(string memory title) external eitherOwnerOrBuyer(title) isValidItem(title) {
    (uint i, ) = searchItem(title);
    if (items[i].status == 'C') {
      owner.transfer(1000000000000000000* items[i].price);
    } else {
      items[i].buyer.transfer(1000000000000000000* items[i].price);
    }
    items[i].status = 'E'; // expired
  }
}
