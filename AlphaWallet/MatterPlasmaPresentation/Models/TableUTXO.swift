//
//  TableUTXO.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import Foundation

struct TableUTXO {
    let utxo: PlasmaUTXOs
    let inWallet: Wallet
    var isSelected: Bool
}

extension TableUTXO: Equatable {
    static func ==(lhs: TableUTXO, rhs: TableUTXO) -> Bool {
        let equalUTXOs = lhs.utxo == rhs.utxo
        return equalUTXOs &&
            lhs.inWallet == rhs.inWallet
    }
}
