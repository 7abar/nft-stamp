// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {NFTStamp} from "../src/NFTStamp.sol";

contract NFTStampTest is Test {
    NFTStamp public stamp;
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        stamp = new NFTStamp(
            "ETHGlobal Bangkok 2025",
            "STAMP",
            "ETHGlobal Bangkok 2025",
            "Nov 2025",
            100,
            0.001 ether
        );
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function test_Mint() public {
        vm.prank(alice);
        stamp.mint{value: 0.001 ether}();
        assertEq(stamp.totalSupply(), 1);
        assertEq(stamp.balanceOf(alice), 1);
    }

    function test_TokenURI() public {
        vm.prank(alice);
        stamp.mint{value: 0.001 ether}();
        string memory uri = stamp.tokenURI(0);
        assertTrue(bytes(uri).length > 0);
        assertEq(bytes(uri)[0], bytes("d")[0]);
    }

    function test_WrongPriceReverts() public {
        vm.prank(alice);
        vm.expectRevert(NFTStamp.WrongPrice.selector);
        stamp.mint{value: 0.002 ether}();
    }

    function test_CloseMinting() public {
        stamp.closeMinting();
        vm.prank(alice);
        vm.expectRevert(NFTStamp.MintingClosed.selector);
        stamp.mint{value: 0.001 ether}();
    }

    function test_MaxSupply() public {
        NFTStamp smallStamp = new NFTStamp("Test", "T", "Test Event", "2025", 1, 0);
        smallStamp.mint{value: 0}();
        vm.expectRevert(NFTStamp.MaxSupplyReached.selector);
        smallStamp.mint{value: 0}();
    }

    function test_Transfer() public {
        vm.prank(alice);
        stamp.mint{value: 0.001 ether}();
        vm.prank(alice);
        stamp.transferFrom(alice, bob, 0);
        assertEq(stamp.balanceOf(alice), 0);
        assertEq(stamp.balanceOf(bob), 1);
    }

    function test_Withdraw() public {
        vm.prank(alice);
        stamp.mint{value: 0.001 ether}();
        uint256 before = address(this).balance;
        stamp.withdraw();
        assertEq(address(this).balance, before + 0.001 ether);
    }

    receive() external payable {}
}
