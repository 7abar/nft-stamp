// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script, console} from "forge-std/Script.sol";
import {NFTStamp} from "../src/NFTStamp.sol";
contract DeployNFTStamp is Script {
    function run() external {
        vm.startBroadcast();
        NFTStamp stamp = new NFTStamp(
            vm.envString("EVENT_NAME"),
            "STAMP",
            vm.envString("EVENT_NAME"),
            vm.envString("EVENT_DATE"),
            vm.envUint("MAX_SUPPLY"),
            vm.envUint("MINT_PRICE")
        );
        console.log("NFTStamp deployed:", address(stamp));
        vm.stopBroadcast();
    }
}
