//
//  PlasmaErrors.swift
//  Alpha-Wallet
//
//  Created by Anton Grigorev on 08.12.2018.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import Foundation

public struct PlasmaErrors {
    public enum NetErrors: Error {
        case cantCreateRequest
        case cantConvertTxData
        case noData
        case errorInListUTXOs
        case errorInUTXOs
        case noAcceptedInfo
        case badResponse
    }
    
    public enum StructureErrors: Error {
        case cantDecodeData
        case cantEncodeData
        case dataIsNotArray
        case isNotList
        case wrongDataCount
        case isNotData
        case wrongBitWidth
        case wrongData
        case wrongKey
        case wrongAddress
    }
}
