//
//  OutputsManagement.swift
//  Alpha-Wallet
//
//  Created by Anton Grigorev on 08.12.2018.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import Foundation
import BigInt

public extension Transaction {
    /// Merge outputs for minimum amount of one output. All outputs with amount less than min will be merged.
    ///
    /// - Parameter untilMinAmount: minimum output amount of one output. In Plasma the minimum amount is preseted in 0.000001 Ether
    /// - Returns: returns Transaction with fixed outputs
    /// - Throws: `StructureErrors.wrongData` if there is some errors in TransactionOutputs inits
    public func mergeOutputs(untilMinAmount: BigUInt) throws -> Transaction {
        let receiverAddress = self.outputs[0].receiverEthereumAddress

        var sortedOutputs: [TransactionOutput] = self.outputs.sorted { $0.amount <= $1.amount }

        var mergedAmount: BigUInt = 0
        var mergedCount: BigUInt = 0

        for output in sortedOutputs {
            let currentOutputAmount = output.amount
            if currentOutputAmount <= (untilMinAmount - mergedAmount) {
                mergedCount += 1
                mergedAmount += currentOutputAmount
            } else {
                break
            }
        }

        guard mergedCount > 1 else {
            return try Transaction(txType: self.txType,
                                   inputs: self.inputs,
                                   outputs: self.outputs)
        }

        sortedOutputs.removeFirst(Int(mergedCount))

        var newOutputsArray: [TransactionOutput] = []
        var index: BigUInt = 0
        for output in sortedOutputs {
            guard let fixedOutput = try? TransactionOutput(outputNumberInTx: index,
                                                      receiverEthereumAddress: receiverAddress,
                                                      amount: output.amount) else {throw PlasmaErrors.StructureErrors.wrongData}
            newOutputsArray.append(fixedOutput)
            index += 1
        }
        guard let mergedOutput = try? TransactionOutput(outputNumberInTx: index,
                                                   receiverEthereumAddress: receiverAddress,
                                                   amount: mergedAmount) else {throw PlasmaErrors.StructureErrors.wrongData}
        newOutputsArray.append(mergedOutput)

        guard let fixedTx = try? Transaction(txType: self.txType,
                                        inputs: self.inputs,
                                        outputs: newOutputsArray) else {throw PlasmaErrors.StructureErrors.wrongData}

        return fixedTx
    }

    /// Merge outputs for fixed number of outputs. Maximum is 3. Сombined outputs with a smaller amount.
    ///
    /// - Parameter forMaxNumber: maximum number of outputs.
    /// - Returns: returns Transaction with fixed outputs
    /// - Throws: `StructureErrors.wrongData` if there is some errors in TransactionOutputs inits
    public func mergeOutputs(forMaxNumber: BigUInt) throws -> Transaction {
        let outputsCount = BigUInt(self.outputs.count)
        print(forMaxNumber)
        print(outputsCount)
        guard forMaxNumber < outputsCount && forMaxNumber != 0 else {
            return try Transaction(txType: self.txType,
                                   inputs: self.inputs,
                                   outputs: self.outputs)
        }
        let outputsCountToMerge: BigUInt = outputsCount - forMaxNumber + 1
        let receiverAddress = self.outputs[0].receiverEthereumAddress

        var sortedOutputs: [TransactionOutput] = self.outputs.sorted { $0.amount <= $1.amount }

        var mergedAmount: BigUInt = 0
        var mergedCount: BigUInt = 0

        for output in sortedOutputs {
            let currentOutputAmount = output.amount
            if mergedCount < outputsCountToMerge {
                mergedCount += 1
                mergedAmount += currentOutputAmount
            } else {
                break
            }
        }

        guard mergedCount == outputsCountToMerge else {
            return try Transaction(txType: self.txType,
                                   inputs: self.inputs,
                                   outputs: self.outputs)
        }

        sortedOutputs.removeFirst(Int(mergedCount))

        var newOutputsArray: [TransactionOutput] = []
        var index: BigUInt = 0
        for output in sortedOutputs {
            guard let fixedOutput = try? TransactionOutput(outputNumberInTx: index,
                                                      receiverEthereumAddress: receiverAddress,
                                                      amount: output.amount) else {throw PlasmaErrors.StructureErrors.wrongData}
            newOutputsArray.append(fixedOutput)
            index += 1
        }
        guard let mergedOutput = try? TransactionOutput(outputNumberInTx: index,
                                                   receiverEthereumAddress: receiverAddress,
                                                   amount: mergedAmount) else {throw PlasmaErrors.StructureErrors.wrongData}
        newOutputsArray.append(mergedOutput)

        guard let fixedTx = try? Transaction(txType: self.txType,
                                        inputs: self.inputs,
                                        outputs: newOutputsArray) else {throw PlasmaErrors.StructureErrors.wrongData}

        return fixedTx
    }

}
