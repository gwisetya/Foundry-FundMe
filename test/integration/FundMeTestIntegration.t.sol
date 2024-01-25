// SPDX_License_Identifier = MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    address user = makeAddr("user");
    uint256 constant SEND_AMOUNT = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant gasPrice = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundFundMe.fundFundMe(address(fundMe));
        address funder = fundMe.getFunder(0);
        assertEq(funder, user);
    }
}
