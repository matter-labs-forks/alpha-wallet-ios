//
//  UTXOCell.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import UIKit
import web3swift

class UTXOCell: UITableViewCell {

    @IBOutlet weak var bottomBackgroundView: UIView!
    @IBOutlet weak var balance: UILabel!

    var link: UTXOsViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(utxo: PlasmaUTXOs, forWallet: Wallet) {
        changeSelectButton(isSelected: false)
        guard let balance = Web3Utils.formatToEthereumUnits(utxo.value,
                                                      toUnits: .eth,
                                                      decimals: 6,
                                                      decimalSeparator: ".") else {
                                                        self.balance.text = "Can't get balance"
                                                        return
        }
        self.balance.text = balance + " ETH"
    }

    func changeSelectButton(isSelected: Bool) {
        let button = selectButton(isSelected: isSelected)
        button.addTarget(self, action: #selector(handleMarkAsSelected), for: .touchUpInside)
        accessoryView = button
    }

    @objc private func handleMarkAsSelected() {
        link?.selectUTXO(cell: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.balance.text = ""
    }
}
