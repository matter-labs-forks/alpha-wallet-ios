//
//  TransactionOutput.swift
//  Alpha-Wallet
//
//  Created by Anton Grigorev on 08.12.2018.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import Foundation
import BigInt
import web3swift

/// An RLP encoded set that describes output in Transaction
public struct PlasmaTransactionOutput {

    let helpers = PlasmaTransactionHelpers()

    public var outputNumberInTx: BigUInt
    public var receiverEthereumAddress: EthereumAddress
    public var amount: BigUInt
    public var data: Data {
        do {
            return try self.serialize()
        } catch {
            return Data()
        }
    }

    /// Creates TransactionOutput object that can be spent as an input in a new transaction
    ///
    /// - Parameters:
    ///   - outputNumberInTx: output number in this transaction
    ///   - receiverEthereumAddress: destionation ethereum address
    ///   - amount: "amount" field
    /// - Throws: `PlasmaErrors.StructureErrors.wrongBitWidth` if bytes count in some parameter is wrong
    public init(outputNumberInTx: BigUInt, receiverEthereumAddress: EthereumAddress, amount: BigUInt) throws {
        guard outputNumberInTx.bitWidth <= outputNumberInTxMaxWidth else {throw PlasmaErrors.StructureErrors.wrongBitWidth}
        guard receiverEthereumAddress.addressData.count <= receiverEthereumAddressByteLength else {throw PlasmaErrors.StructureErrors.wrongBitWidth}
        guard amount.bitWidth <= amountMaxWidth else {throw PlasmaErrors.StructureErrors.wrongBitWidth}

        self.outputNumberInTx = outputNumberInTx
        self.receiverEthereumAddress = receiverEthereumAddress
        self.amount = amount
    }

    /// Creates TransactionOutput object that can be spent as an input in a new transaction
    ///
    /// - Parameter data: encoded Data of TransactionOutput
    /// - Throws: throws various `PlasmaErrors.StructureErrors` if decoding is wrong or decoded data is wrong in some way
    public init(data: Data) throws {

        guard let dataDecoded = PlasmaRLP.decode(data) else {throw PlasmaErrors.StructureErrors.cantDecodeData}
        guard dataDecoded.isList else {throw PlasmaErrors.StructureErrors.isNotList}
        guard let count = dataDecoded.count else {throw PlasmaErrors.StructureErrors.wrongDataCount}
        let dataArray: PlasmaRLP.RLPItem
        guard let firstItem = dataDecoded[0] else {throw PlasmaErrors.StructureErrors.dataIsNotArray}
        if count > 1 {
            dataArray = dataDecoded
        } else {
            dataArray = firstItem
        }
        guard dataArray.count == 3 else {throw PlasmaErrors.StructureErrors.wrongDataCount}

        guard let outputNumberInTxData = dataArray[0]?.data else {throw PlasmaErrors.StructureErrors.isNotData}
        guard let receiverEthereumAddressData = dataArray[1]?.data else {throw PlasmaErrors.StructureErrors.isNotData}
        guard let amountData = dataArray[2]?.data else {throw PlasmaErrors.StructureErrors.isNotData}

        let outputNumberInTx = BigUInt(outputNumberInTxData)
        guard let receiverEthereumAddress = EthereumAddress(receiverEthereumAddressData) else {throw PlasmaErrors.StructureErrors.wrongData}
        let amount = BigUInt(amountData)

        guard outputNumberInTx.bitWidth <= outputNumberInTxMaxWidth else {throw PlasmaErrors.StructureErrors.wrongBitWidth}
        guard receiverEthereumAddress.addressData.count <= receiverEthereumAddressByteLength else {throw PlasmaErrors.StructureErrors.wrongDataCount}
        guard amount.bitWidth <= amountMaxWidth else {throw PlasmaErrors.StructureErrors.wrongBitWidth}

        self.outputNumberInTx = outputNumberInTx
        self.receiverEthereumAddress = receiverEthereumAddress
        self.amount = amount
    }

    /// Serializes TransactionOutput
    ///
    /// - Returns: encoded AnyObject array consisted of TransactionOutput items
    /// - Throws: `PlasmaErrors.StructureErrors.cantEncodeData` if data can't be encoded
    public func serialize() throws -> Data {
        let dataArray = self.prepareForRLP()
        guard let encoded = PlasmaRLP.encode(dataArray) else {throw PlasmaErrors.StructureErrors.cantEncodeData}
        return encoded
    }

    /// Plases TransactionOutput items in AnyObject array
    ///
    /// - Returns: AnyObject array of TransactionOutput items in Data type
    public func prepareForRLP() -> [AnyObject] {
        let outputNumberData = self.outputNumberInTx.serialize().setLengthLeft(outputNumberInTxByteLength)
        let addressData = self.receiverEthereumAddress.addressData
        let amountData = self.amount.serialize().setLengthLeft(amountByteLength)
        let dataArray = [outputNumberData, addressData, amountData] as [AnyObject]
        return dataArray
    }
}

extension PlasmaTransactionOutput: Equatable {
    public static func ==(lhs: PlasmaTransactionOutput, rhs: PlasmaTransactionOutput) -> Bool {
        return lhs.outputNumberInTx == rhs.outputNumberInTx
            && lhs.receiverEthereumAddress.address == rhs.receiverEthereumAddress.address
            && lhs.amount == rhs.amount
            && lhs.data == rhs.data
    }
}
