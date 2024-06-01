// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
      FundMe fundMe; 
      address USER = makeAddr("user");
      uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000000;
      uint256 constant STARTING_BALANCE = 10 ether;
      uint256 constant GAS_PRICE = 1;
    function setUp() external{
      //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
      DeployFundMe deployFundMe = new DeployFundMe();
      fundMe = deployFundMe.run();
      vm.deal(USER,STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view{
      assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }
   
    function testFundUpdatesFundedDataStructure() public {
       vm.prank(USER);
       fundMe.fund{value: SEND_VALUE}();
       uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
       assertEq(amountFunded,SEND_VALUE);
    }
     function testFundFailsithoutEnoughETH() public {
       
        vm.expectRevert();
        fundMe.fund();
    }

    function testaddsFunderToArrayOfFunders() public  {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);

    }
   modifier funded(){
    vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
     _;
   }

    function testOnlyownerCanWithdraw() public funded{
    
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }
    
    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert

        uint256 endingownerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingOwnerBalance+startingFundMeBalance, endingownerBalance);
    } 

    function testWithDrawFromMultipleFunders() public funded {
      uint160 numberOfFunders = 10;
      uint160 startFunderIndex = 1;
      for(uint160 i = startFunderIndex ; i<numberOfFunders;i++){
           hoax(address(i),SEND_VALUE);
           fundMe.fund{value: SEND_VALUE}();

      } 
        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
     

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);


    }

     function testWithDrawFromMultipleFundersCheaper() public funded {
      uint160 numberOfFunders = 10;
      uint160 startFunderIndex = 1;
      for(uint160 i = startFunderIndex ; i<numberOfFunders;i++){
           hoax(address(i),SEND_VALUE);
           fundMe.fund{value: SEND_VALUE}();

      } 
        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act 
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
     

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);


    }

}
