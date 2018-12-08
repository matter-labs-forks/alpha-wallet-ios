// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

//Must be a class, and not a struct, otherwise changing `filter` will silently create a copy of TokensViewModel when user taps to change the filter in the UI and break filtering
class TokensViewModel {
    private let tokens: [TokenObject]
    private let tickers: [String: CoinTicker]?

    private var amount: String? {
        var totalAmount: Double = 0
        filteredTokens.forEach { token in
            totalAmount += amount(for: token)
        }
        guard totalAmount != 0 else { return "--" }
        return CurrencyFormatter.formatter.string(from: NSNumber(value: totalAmount))
    }

    private func amount(for token: TokenObject) -> Double {
        guard let tickers = tickers else { return 0 }
        guard !token.valueBigInt.isZero, let tickersSymbol = tickers[token.contract] else { return 0 }
        let tokenValue = CurrencyFormatter.plainFormatter.string(from: token.valueBigInt, decimals: token.decimals).doubleValue
        let price = Double(tickersSymbol.price_usd) ?? 0
        return tokenValue * price
    }

    let etherTokenContract: String
    var filter: WalletFilter = .all
    var filteredTokens: [TokenObject] {
        switch filter {
        case .all:
            return tokens
        case .currencyOnly:
            return tokens.filter { $0.type == .ether || $0.type == .erc20 }
        case .assetsOnly:
            return tokens.filter { $0.type != .ether && $0.type != .erc20 }
        case .collectiblesOnly:
            return tokens.filter { $0.type == .erc721 && !$0.balance.isEmpty }
        case .plasma:
            return tokens.filter { $0.type == .erc721 && !$0.balance.isEmpty }
        case .keyword(let keyword):
            let lowercasedKeyword = keyword.trimmed.lowercased()
            if lowercasedKeyword.isEmpty {
                return tokens
            } else {
                return tokens.filter { $0.name.trimmed.lowercased().contains(lowercasedKeyword) || $0.symbol.trimmed.lowercased().contains(lowercasedKeyword) }
            }
        }
    }

    var headerBackgroundColor: UIColor {
        return .white
    }

    var title: String {
        return R.string.localizable.walletTokensTabbarItemTitle()
    }

    var backgroundColor: UIColor {
        return Colors.appBackground
    }

    var shouldShowTable: Bool {
        switch filter {
        case .all, .currencyOnly, .assetsOnly, .keyword, .plasma:
            return hasContent
        case .collectiblesOnly:
            return false
        }
    }

    var shouldShowCollectiblesCollectionView: Bool {
        switch filter {
        case .all, .currencyOnly, .assetsOnly, .keyword, .plasma:
            return false
        case .collectiblesOnly:
            return hasContent
        }
    }

    var hasContent: Bool {
        return !filteredTokens.isEmpty
    }

    var numberOfSections: Int {
        return 1
    }

    func numberOfItems(for section: Int) -> Int {
        return filteredTokens.count
    }

    func item(for row: Int, section: Int) -> TokenObject {
        return filteredTokens[row]
    }

    func ticker(for token: TokenObject) -> CoinTicker? {
        return tickers?[token.contract]
    }

    func canDelete(for row: Int, section: Int) -> Bool {
        let token = item(for: row, section: section)
        if etherTokenContract.sameContract(as: token.contract) {
            return false
        }
        return true
    }

    init(
        config: Config,
        tokens: [TokenObject],
        tickers: [String: CoinTicker]?
    ) {
        self.etherTokenContract = TokensDataStore.etherToken(for: config).contract
        self.tokens = tokens
        self.tickers = tickers
    }
}
