// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AMMFactory} from "../../src/AMMFactory.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {MockAMToken} from "../mocks/MockAMToken.sol";

contract AMMFactoryTest is Test {
    AMMFactory internal factory;
    MockAMToken internal tokenA;
    MockAMToken internal tokenB;

    function setUp() public {
        AMMFactory implementation = new AMMFactory();
        bytes memory initData = abi.encodeCall(AMMFactory.initialize, (address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        factory = AMMFactory(address(proxy));
        tokenA = new MockAMToken("A", "A");
        tokenB = new MockAMToken("B", "B");
    }

    function test_CreatePairCreate2() public {
        address pair = factory.createPairCreate2(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertEq(factory.allPairsLength(), 1);
    }

    function test_PairForMatchesDeployed() public {
        address predicted = factory.pairFor(address(tokenA), address(tokenB));
        address pair = factory.createPairCreate2(address(tokenA), address(tokenB));
        assertEq(predicted, pair);
    }

    function test_CreatePairCreate() public {
        address pair = factory.createPairCreate(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));
        assertEq(factory.allPairsLength(), 1);
    }

    function test_Revert_DuplicatePairCreate2() public {
        factory.createPairCreate2(address(tokenA), address(tokenB));
        vm.expectRevert();
        factory.createPairCreate2(address(tokenA), address(tokenB));
    }

    function test_Revert_DuplicatePairCreate() public {
        factory.createPairCreate(address(tokenA), address(tokenB));
        vm.expectRevert();
        factory.createPairCreate(address(tokenA), address(tokenB));
    }

    function test_SetFeeRecipient() public {
        address recipient = makeAddr("fee");
        factory.setFeeRecipient(recipient);
        assertEq(factory.feeRecipient(), recipient);
    }

    function test_Revert_SetFeeRecipientZero() public {
        vm.expectRevert();
        factory.setFeeRecipient(address(0));
    }

    function test_Revert_CreatePairIdentical() public {
        vm.expectRevert();
        factory.createPair(address(tokenA), address(tokenA));
    }

    function test_SortTokens() public {
        (address t0, address t1) = factory.sortTokens(address(tokenB), address(tokenA));
        assertTrue(t0 < t1);
    }

    function test_OwnershipOnInit() public {
        assertEq(factory.owner(), address(this));
    }
}
