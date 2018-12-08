//
//  ArrayExtension.swift
//  Alpha-Wallet
//
//  Created by Anton Grigorev on 08.12.2018.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import Foundation

extension Array {
    public func split(intoChunksOf chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            let endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize
            return Array(self[$0..<$0.advanced(by: endIndex)])
        }
    }
}
