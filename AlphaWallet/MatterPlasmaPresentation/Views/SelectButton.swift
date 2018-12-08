//
//  SelectButton.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import UIKit

func selectButton(isSelected: Bool) -> UIButton {
    let button = UIButton(type: .system)
    let name = isSelected ? "ticket_bundle_checked" : "ticket_bundle_unchecked"
    button.setImage(UIImage(named: name), for: .normal)
    button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    return button
}
