// Copyright © 2017 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import CryptoSwift
import Foundation

public struct Address: Hashable, CustomStringConvertible {
    /// Raw address bytes, length 20.
    public private(set) var data: Data

    /// EIP55 representation of the address.
    public let eip55String: String

    /// Creates an address with `Data`.
    ///
    /// - Precondition: data contains exactly 20 bytes
    public init(data: Data) {
        precondition(data.count == 20, "Address length should be 20 bytes")
        precondition(Address.checkNotBurnAddress(data: data))
        self.data = data
        eip55String = Address.computeEIP55String(for: data)
    }

    /// Creates an address with an hexadecimal string representation.
    ///
    /// - Note: User input should be validated by using `init(eip55:)`.
    public init?(string: String) {
        guard let data = Data(hexString: string), data.count == 20 else {
            return nil
        }
        let notBurnAddress = Address.checkNotBurnAddress(data: data)
        if !notBurnAddress {
            return nil
        }
        self.data = data
        eip55String = Address.computeEIP55String(for: data)
    }

    public init?(uncheckedAgainstNullAddress: String) {
        guard let data = Data(hexString: uncheckedAgainstNullAddress), data.count == 20 else {
            return nil
        }
        self.data = data
        eip55String = Address.computeEIP55String(for: data)
    }

    /// Creates an address with an EIP55 string representation.
    ///
    /// This initializer will fail if the EIP55 string fails validation.
    public init?(eip55 string: String) {
        guard let data = Data(hexString: string), data.count == 20 else {
            return nil
        }
        self.data = data
        let notBurnAddress = Address.checkNotBurnAddress(data: data)
        if !notBurnAddress {
            return nil
        }
        eip55String = Address.computeEIP55String(for: data)
        if eip55String != string {
            return nil
        }
    }

    public var description: String {
        return eip55String
    }

    public var hashValue: Int {
        return data.hashValue
    }

    public static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.data == rhs.data
    }

    //While it is very difficult to catch every case of burn address
    //This catches many by checking if all bytes are the same
    private static func checkNotBurnAddress(data: Data) -> Bool {
        let addressBytes = Array(data)
        for i in 0..<addressBytes.count {
            if(addressBytes[i] != addressBytes[0]) {
                return true
            }
        }
        return false
    }

}

extension Address {
    /// Converts the address to an EIP55 checksumed representation.
    private static func computeEIP55String(for data: Data) -> String {
        let addressString = data.hexString
        let hashInput = addressString.data(using: .ascii)!
        let hash = Data(bytes: SHA3(variant: .keccak256).calculate(for: hashInput.bytes)).hexString
        var string = "0x"
        for (a, h) in zip(addressString, hash) {
            switch (a, h) {
            case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                string.append(a)
            case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                string.append(contentsOf: String(a).uppercased())
            default:
                string.append(contentsOf: String(a).lowercased())
            }
        }

        return string
    }
}
