//
//  BlockHelpers.swift
//  Alpha-Wallet
//
//  Created by Anton Grigorev on 08.12.2018.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import Foundation

extension BlockHeader {
    /// Prinets elements of Block header
    public func printElements() {
        print("---------------------------")
        print("BlockHeader:")
        print("blockNumber: \(self.blockNumber.description)")
        print("numberOfTxInBlock: \(self.numberOfTxInBlock.description)")
        print("merkleRootOfTheTxTree: \(self.merkleRootOfTheTxTree.toHexString())")
        print("parentHash: \(self.parentHash.toHexString())")
        print("r: \(self.r.toHexString())")
        print("s: \(self.s.toHexString())")
        print("v: \(self.v.description)")
    }
}
