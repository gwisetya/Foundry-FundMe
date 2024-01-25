// SPDX_License_Identifier = MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address user = makeAddr("user");
    uint256 constant SEND_AMOUNT = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant gasPrice = 1;

    function setUp() external {
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function testMinimum() external {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testPriceFeedVersionIsAccurate() external {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFails() external {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() external {
        vm.prank(user);
        fundMe.fund{value: SEND_AMOUNT}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq(amountFunded, SEND_AMOUNT);
    }

    function testAddsFunderToArrayofFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, user);
    }

    function testOnlyOwnerWithdraw() public funded {
        vm.expectRevert();
        vm.prank(user);
        fundMe.withdraw();
    }

    function testWithdraw() public funded {
        //arrange
        uint256 OwnerStartingBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + OwnerStartingBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_AMOUNT);
            fundMe.fund{value: SEND_AMOUNT};
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(gasPrice);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: SEND_AMOUNT};
        _;
    }
}
