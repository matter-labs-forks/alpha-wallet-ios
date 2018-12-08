//
//  PlasmaTransactionsService.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import Foundation
import BigInt
import web3swift

public final class PlasmaTransactionsService {
    
    let accountService = AccountService()
    
    func signAndSend(transaction: PlasmaTransaction, inSession: WalletSession) -> Bool {
        do {
            guard let privKey = accountService.getPrivKey() else {
                return false
            }
            let signedTransaction = try transaction.sign(privateKey: privKey)
            let chainID = inSession.config.chainID
            let mainnet = chainID == 1
            let testnet = !mainnet && chainID == 4
            if !testnet && !mainnet {
                return false
            }
            let result = try PlasmaService().sendRawTX(transaction: signedTransaction, onTestnet: testnet)
            return result
        } catch {
            return false
        }
    }
    
    func formMergeUTXOsTransaction(chosenUTXOs: [TableUTXO], wallet: Wallet) -> PlasmaTransaction? {
        var inputs = [PlasmaTransactionInput]()
        var mergedAmount: BigUInt = 0
        do {
            for utxo in chosenUTXOs {
                let input = try? utxo.utxo.toTransactionInput()
                if let i = input {
                    inputs.append(i)
                    mergedAmount += i.amount
                }
            }
            guard let address = EthereumAddress(wallet.address.description) else {
                return nil
            }
            let output = try PlasmaTransactionOutput(outputNumberInTx: 0,
                                                     receiverEthereumAddress: address,
                                                     amount: mergedAmount)
            let outputs = [output]
            let transaction = try PlasmaTransaction(txType: .merge,
                                                    inputs: inputs,
                                                    outputs: outputs)
            return transaction
        } catch {
            return nil
        }
    }
    
    func formSplitUTXOsTransaction(utxo: PlasmaUTXOs, address: String, amount: String, wallet: Wallet) -> PlasmaTransaction? {
        do {
            let input = try utxo.toTransactionInput()
            let inputs = [input]
            let destinationAddress = address.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard let floatAmount = Float(amount) else {
                return nil
            }
            let uintAmount = BigUInt( floatAmount * 1000000 )
            let amountSendInETH = uintAmount * BigUInt(1000000000000)
            let amountStayInETH = input.amount - amountSendInETH
            
            guard let ethDestinationAddress = EthereumAddress(destinationAddress) else {
                return nil
            }
            guard let ethCurrentAddress = EthereumAddress(wallet.address.description) else {
                return nil
            }
            
            let output1 = try PlasmaTransactionOutput(outputNumberInTx: 0,
                                                      receiverEthereumAddress: ethDestinationAddress,
                                                      amount: amountSendInETH)
            let output2 = try PlasmaTransactionOutput(outputNumberInTx: 1,
                                                      receiverEthereumAddress: ethCurrentAddress,
                                                      amount: amountStayInETH)
            
            let outputs = [output1, output2]
            
            let transaction = try PlasmaTransaction(txType: .split, inputs: inputs, outputs: outputs)
            return transaction
            
        } catch {
            return nil
        }
    }
    
}
