// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address payable[] public players;
    address public manager;

    constructor(){
        manager = msg.sender;
        players.push(payable(manager));        
    }

    receive() external payable{
        require(msg.sender != manager);
        require(msg.value == 0.1 ether);
        // payable(msg.sender) - is the convertion plain address to payable address
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);

        uint r = random();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];

        uint amountForManager = (getBalance() * 10) / 100;
        uint amountForWinner = (getBalance() * 90) / 100;

        winner.transfer(amountForManager);
        payable(manager).transfer(amountForWinner);

        players = new address payable[](0); // reset the lottery
    }

}