// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import PromiseKit

struct OpenSeaNonFungibleTokenCardRowViewModel {
    private static var imageGenerator = ConvertSVGToPNG()
    private let tokenHolder: TokenHolder
    private let displayHelper: OpenSeaNonFungibleTokenDisplayHelper

    let areDetailsVisible: Bool
    let width: CGFloat
    var bigImage: Promise<UIImage>?

    init(tokenHolder: TokenHolder, areDetailsVisible: Bool, width: CGFloat) {
        self.tokenHolder = tokenHolder
        self.areDetailsVisible = areDetailsVisible
        self.width = width
        self.displayHelper = OpenSeaNonFungibleTokenDisplayHelper(contract: tokenHolder.contractAddress)

        let tokenId = tokenHolder.values["tokenId"] as? String
        self.bigImage = OpenSeaNonFungibleTokenCardRowViewModel.imageGenerator.withDownloadedImage(fromURL: imageUrl, forTokenId: tokenId, withPrefix: tokenHolder.contractAddress)
    }

    var contentsBackgroundColor: UIColor {
        return Colors.appWhite
    }

    var bigImageBackgroundColor: UIColor {
        //Instead of checking the API for backgroundColor first, we use the backgroundColor returned by API only if we are sure, i.e. had manually verified
        if displayHelper.imageHasBackgroundColor {
            return .clear
        } else {
            if let color = tokenHolder.values["backgroundColor"] as? String, !color.isEmpty {
                return UIColor(hex: color)
            } else {
                return UIColor(red: 247, green: 197, blue: 196)
            }
        }
    }

    var titleColor: UIColor {
        return Colors.appText
    }

    var subtitleColor: UIColor {
        return UIColor(red: 112, green: 112, blue: 112)
    }

    var titleFont: UIFont {
        if ScreenChecker().isNarrowScreen() {
            return Fonts.semibold(size: 13)!
        } else {
            return Fonts.semibold(size: 17)!
        }
    }

    var descriptionFont: UIFont {
        return Fonts.light(size: 13)!
    }

    var stateColor: UIColor {
        return .white
    }

    var stateFont: UIFont {
        if ScreenChecker().isNarrowScreen() {
            return Fonts.semibold(size: 10)!
        } else {
            return Fonts.semibold(size: 12)!
        }
    }

    var detailsFont: UIFont {
        return Fonts.light(size: 16)!
    }

    var urlButtonText: String {
        return R.string.localizable.openSeaNonFungibleTokensUrlOpen(tokenHolder.name)
    }

    var title: String {
        let tokenId = tokenHolder.values["tokenId"] as? String ?? ""
        if let name = tokenHolder.values["name"] as? String, !name.isEmpty {
            return name
        } else {
            return displayHelper.title(fromTokenName: tokenHolder.name, tokenId: tokenId)
        }
    }

    var attributesTitleFont: UIFont {
        if ScreenChecker().isNarrowScreen() {
            return Fonts.semibold(size: 11)!
        } else {
            return Fonts.semibold(size: 15)!
        }
    }

    var attributesTitle: String {
        return displayHelper.attributesLabelName
    }

    var rankingsTitle: String {
        return displayHelper.rankingsLabelName
    }

    var statsTitle: String {
        return displayHelper.statsLabelName
    }

    var isAttributesTitleHidden: Bool {
        return attributes.isEmpty
    }

    var isRankingsTitleHidden: Bool {
        return rankings.isEmpty
    }

    var isStatsTitleHidden: Bool {
        return stats.isEmpty
    }

    var subtitleFont: UIFont {
        if ScreenChecker().isNarrowScreen() {
            return Fonts.semibold(size: 11)!
        } else {
            return Fonts.semibold(size: 14)!
        }
    }

    var nonFungibleIdIconText: String {
        return "#"
    }

    var nonFungibleIdIconTextColor: UIColor {
        return .init(red: 192, green: 192, blue: 192)
    }

    var nonFungibleIdTextColor: UIColor {
        return .init(red: 155, green: 155, blue: 155)
    }

    var generationTextColor: UIColor {
        return .init(red: 155, green: 155, blue: 155)
    }

    var cooldownTextColor: UIColor {
        return .init(red: 155, green: 155, blue: 155)
    }

    var generationIcon: UIImage {
        return R.image.generation()!
    }

    var cooldownIcon: UIImage {
        return R.image.cooldown()!
    }

    var tokenId: String {
        return tokenHolder.values["tokenId"] as? String ?? ""
    }

    var subtitle1: String? {
        guard let name = displayHelper.subtitle1TraitName else { return nil }
        let traits =  tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        guard let generation = traits.first(where: { $0.type == name }) else { return nil }
        let value = displayHelper.mapTraitsToDisplayValue(name: name, value: generation.value)
        return value
    }

    var subtitle2: String? {
        guard let name = displayHelper.subtitle2TraitName else { return nil }
        let traits =  tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        guard let cooldown = traits.first(where: { $0.type == name }) else { return nil }
        let value = displayHelper.mapTraitsToDisplayValue(name: name, value: cooldown.value)
        return value
    }

    var subtitle3: String? {
        guard let name = displayHelper.subtitle3TraitName else { return nil }
        let traits =  tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        guard let cooldown = traits.first(where: { $0.type == name }) else { return nil }
        let value = displayHelper.mapTraitsToDisplayValue(name: name, value: cooldown.value)
        return value
    }

    var description: String {
        return tokenHolder.values["description"] as? String ?? ""
    }

    var thumbnailImageUrl: URL? {
        guard let url = tokenHolder.values["thumbnailUrl"] as? String else { return nil }
        return URL(string: url)
    }

    var imageUrl: URL? {
        guard let url = tokenHolder.values["imageUrl"] as? String else { return nil }
        return URL(string: url)
    }

    var externalLink: URL? {
        guard let url = tokenHolder.values["externalLink"] as? String else { return nil }
        return URL(string: url)
    }

    var externalLinkButtonHidden: Bool {
        return externalLink == nil
    }

    var attributes: [OpenSeaNonFungibleTokenAttributeCellViewModel] {
        let traits = tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        let traitsToDisplay = traits.filter { displayHelper.shouldDisplayAttribute(name: $0.type) }
        return traitsToDisplay.map { mapTraitsToProperName(name: $0.type, value: $0.value) }
    }

    var rankings: [OpenSeaNonFungibleTokenAttributeCellViewModel] {
        let traits = tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        let traitsToDisplay = traits.filter { displayHelper.shouldDisplayRanking(name: $0.type) }
        return traitsToDisplay.map { mapTraitsToProperName(name: $0.type, value: $0.value) }
    }

    var stats: [OpenSeaNonFungibleTokenAttributeCellViewModel] {
        let traits = tokenHolder.values["traits"] as? [OpenSeaNonFungibleTrait] ?? []
        let traitsToDisplay = traits.filter { displayHelper.shouldDisplayStat(name: $0.type) }
        return traitsToDisplay.map { mapTraitsToProperName(name: $0.type, value: $0.value) }
    }

    var areImagesHidden: Bool {
        return tokenHolder.status == .availableButDataUnavailable || imageUrl == nil
    }

    var isDescriptionHidden: Bool {
        return tokenHolder.status == .availableButDataUnavailable
    }

    var urlButtonTextColor: UIColor {
        return UIColor(red: 84, green: 84, blue: 84)
    }

    var urlButtonFont: UIFont {
        return Fonts.semibold(size: 12)!
    }

    var urlButtonImage: UIImage {
        return R.image.openSeaNonFungibleButtonArrow()!
    }

    private func mapTraitsToProperName(name: String, value: String) -> OpenSeaNonFungibleTokenAttributeCellViewModel {
        let displayName = displayHelper.mapTraitsToDisplayName(name: name)
        let displayValue = displayHelper.mapTraitsToDisplayValue(name: name, value: value)
        return OpenSeaNonFungibleTokenAttributeCellViewModel(name: displayName, value: displayValue)
    }

    var areSubtitlesHidden: Bool {
        return subtitle1 == nil && subtitle2 == nil && subtitle3 == nil
    }

    var isSubtitle1Hidden: Bool {
        return subtitle1 == nil
    }

    var isSubtitle2Hidden: Bool {
        return subtitle2 == nil
    }

    var isSubtitle3Hidden: Bool {
        return subtitle3 == nil
    }

    //We let the big image bleed out of its container view because CryptoKitty images has a huge empty marge around the kitties. Careful that this also fits iPhone 5s
    var bleedForBigImage: CGFloat {
        if displayHelper.hasLotsOfEmptySpaceAroundBigImage {
            if ScreenChecker().isNarrowScreen() {
                return 24
            } else {
                return 34
            }
        } else {
            return 0
        }
    }
}