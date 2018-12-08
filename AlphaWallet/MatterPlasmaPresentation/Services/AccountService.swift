//
//  AccountService.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import Foundation

public final class AccountService {
    public func getPrivKey() -> Data? {
        //        guard let address = wallet?.address else {return nil}
        //        // TODO: - It's not secure
        //        guard let keys: EtherKeystore = self.keystore as? EtherKeystore else {return nil}
        //        guard let account = keys.getAccount(for: address) else {return nil}
        ////        guard let password = keystore?.getPassword(for: account) else {return nil}
        //        let result = keys.exportPrivateKey(account: account)
        //        switch result {
        //        case .success(let privKey):
        //            return privKey
        //        default:
        //            return nil
        //        }
        return Data(hex: "BDBA6C3D375A8454993C247E2A11D3E81C9A2CE9911FF05AC7FF0FCCBAC554B5")
    }
}
