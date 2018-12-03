// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import WebKit

class TokenCardRowView: UIView {
	let checkboxImageView = UIImageView(image: R.image.ticket_bundle_unchecked())
	let background = UIView()
	let stateLabel = UILabel()
	private let tokenCountLabel = UILabel()
	private let venueLabel = UILabel()
	private let dateLabel = UILabel()
	private let categoryLabel = UILabel()
	private let matchLabel = UILabel()
	private let dateImageView = UIImageView()
	private let seatRangeImageView = UIImageView()
	private let categoryImageView = UIImageView()
	private let cityLabel = UILabel()
	private let timeLabel = UILabel()
	private let teamsLabel = UILabel()
	private var detailsRowStack: UIStackView?
    private let showCheckbox: Bool
	private let nameWebView = WKWebView(frame: .zero, configuration: .init())
	private let introductionWebView = WKWebView(frame: .zero, configuration: .init())
	private let instructionsWebView = WKWebView(frame: .zero, configuration: .init())
	private var canDetailsBeVisible = true
    var areDetailsVisible = false {
		didSet {
			guard canDetailsBeVisible else { return }
			detailsRowStack?.isHidden = !areDetailsVisible
		}
    }
	private let bottomRowStack: UIStackView
	private let spaceAboveBottomRowStack = UIView.spacer(height: 10)
	private var onlyShowTitle: Bool = false {
		didSet {
			if onlyShowTitle {
				canDetailsBeVisible = false
				bottomRowStack.isHidden = true
				venueLabel.isHidden = true
				spaceAboveBottomRowStack.isHidden = true
			} else {
				canDetailsBeVisible = true
				bottomRowStack.isHidden = false
				venueLabel.isHidden = false
				spaceAboveBottomRowStack.isHidden = false
			}
		}
	}

	init(showCheckbox: Bool = false) {
        self.showCheckbox = showCheckbox

		bottomRowStack = [dateImageView, dateLabel, seatRangeImageView, teamsLabel, .spacerWidth(7), categoryImageView, matchLabel].asStackView(spacing: 7, contentHuggingPriority: .required)

		super.init(frame: .zero)

		checkboxImageView.translatesAutoresizingMaskIntoConstraints = false
        if showCheckbox {
            addSubview(checkboxImageView)
        }

		background.translatesAutoresizingMaskIntoConstraints = false
		addSubview(background)

		let topRowStack = [tokenCountLabel, categoryLabel].asStackView(spacing: 15, contentHuggingPriority: .required)
		let detailsRow0 = [timeLabel, cityLabel].asStackView(contentHuggingPriority: .required)

		detailsRowStack = [
			.spacer(height: 10),
			detailsRow0,
		].asStackView(axis: .vertical, contentHuggingPriority: .required)
		detailsRowStack?.isHidden = true

		//TODO variable names are unwieldy after several rounds of changes, fix them
		let stackView = [
			stateLabel,
			topRowStack,
			venueLabel,
            spaceAboveBottomRowStack,
			bottomRowStack,
			detailsRowStack!,
			nameWebView,
			introductionWebView,
			instructionsWebView,
		].asStackView(axis: .vertical, contentHuggingPriority: .required)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .leading
		background.addSubview(stackView)

		// TODO extract constant. Maybe StyleLayout.sideMargin
		let xMargin  = CGFloat(7)
		let yMargin  = CGFloat(5)
		var checkboxRelatedConstraints = [NSLayoutConstraint]()
		if showCheckbox {
			checkboxRelatedConstraints.append(checkboxImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: xMargin))
			checkboxRelatedConstraints.append(checkboxImageView.centerYAnchor.constraint(equalTo: centerYAnchor))
			checkboxRelatedConstraints.append(background.leadingAnchor.constraint(equalTo: checkboxImageView.trailingAnchor, constant: xMargin))
			if ScreenChecker().isNarrowScreen() {
				checkboxRelatedConstraints.append(checkboxImageView.widthAnchor.constraint(equalToConstant: 20))
				checkboxRelatedConstraints.append(checkboxImageView.heightAnchor.constraint(equalToConstant: 20))
			} else {
				//Have to be hardcoded and not rely on the image's size because different string lengths for the text fields can force the checkbox to shrink
				checkboxRelatedConstraints.append(checkboxImageView.widthAnchor.constraint(equalToConstant: 28))
				checkboxRelatedConstraints.append(checkboxImageView.heightAnchor.constraint(equalToConstant: 28))
			}
		} else {
			checkboxRelatedConstraints.append(background.leadingAnchor.constraint(equalTo: leadingAnchor, constant: xMargin))
		}

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 21),
			stackView.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -21),
			stackView.topAnchor.constraint(equalTo: background.topAnchor, constant: 16),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: background.bottomAnchor, constant: -16),

			background.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -xMargin),
			background.topAnchor.constraint(equalTo: topAnchor, constant: yMargin),
			background.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -yMargin),

            nameWebView.heightAnchor.constraint(equalToConstant: 30),
			introductionWebView.heightAnchor.constraint(equalToConstant: 200),
			instructionsWebView.heightAnchor.constraint(equalToConstant: 200),
			nameWebView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			introductionWebView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			instructionsWebView.widthAnchor.constraint(equalTo: stackView.widthAnchor),

			stateLabel.heightAnchor.constraint(equalToConstant: 22),
		] + checkboxRelatedConstraints)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configure(viewModel: TokenCardRowViewModelProtocol) {
		background.backgroundColor = viewModel.contentsBackgroundColor
		background.layer.cornerRadius = 20
		background.layer.shadowRadius = 3
		background.layer.shadowColor = UIColor.black.cgColor
		background.layer.shadowOffset = CGSize(width: 0, height: 0)
		background.layer.shadowOpacity = 0.14
		background.layer.borderColor = UIColor.black.cgColor

		stateLabel.backgroundColor = viewModel.stateBackgroundColor
		stateLabel.layer.cornerRadius = 8
		stateLabel.clipsToBounds = true
		stateLabel.textColor = viewModel.stateColor
		stateLabel.font = viewModel.subtitleFont

		tokenCountLabel.textColor = viewModel.countColor
		tokenCountLabel.font = viewModel.tokenCountFont

		venueLabel.textColor = viewModel.titleColor
		venueLabel.font = viewModel.venueFont

		dateLabel.textColor = viewModel.subtitleColor
		dateLabel.font = viewModel.subtitleFont

		categoryLabel.textColor = viewModel.titleColor
		categoryLabel.font = viewModel.titleFont

		matchLabel.textColor = viewModel.subtitleColor
		matchLabel.font = viewModel.subtitleFont

		dateImageView.image = R.image.calendar()?.withRenderingMode(.alwaysTemplate)
		seatRangeImageView.image = R.image.ticket()?.withRenderingMode(.alwaysTemplate)
		categoryImageView.image = R.image.category()?.withRenderingMode(.alwaysTemplate)

		dateImageView.tintColor = viewModel.iconsColor
		seatRangeImageView.tintColor = viewModel.iconsColor
		categoryImageView.tintColor = viewModel.iconsColor

		cityLabel.textColor = viewModel.subtitleColor
		cityLabel.font = viewModel.detailsFont

		timeLabel.textColor = viewModel.subtitleColor
		timeLabel.font = viewModel.detailsFont

		teamsLabel.textColor = viewModel.subtitleColor
		teamsLabel.font = viewModel.subtitleFont

		tokenCountLabel.text = viewModel.tokenCount

		venueLabel.text = viewModel.venue

		dateLabel.text = viewModel.date

		timeLabel.text = viewModel.time

		cityLabel.text = viewModel.city

		categoryLabel.text = viewModel.category

		teamsLabel.text = viewModel.teams

		matchLabel.text = viewModel.match

		onlyShowTitle = viewModel.onlyShowTitle

        //TODO this if-else-if is so easy to miss implementing either the if(s) because we aren't taking advantage of type-checking
		if let vm = viewModel as? TokenCardRowViewModel {
			vm.subscribeBuilding { [weak self] building in
				guard let strongSelf = self else { return }
				strongSelf.categoryLabel.text = building
			}

			vm.subscribeLocality { [weak self] locality in
				guard let strongSelf = self else { return }
				strongSelf.cityLabel.text = ", \(locality)"
			}

			vm.subscribeExpired { [weak self] expired in
				guard let strongSelf = self else { return }
				strongSelf.teamsLabel.text = expired
			}

			vm.subscribeStreetStateCountry { [weak self] streetStateCountry in
				guard let strongSelf = self else { return }
				strongSelf.venueLabel.text = streetStateCountry
			}
		} else if let vm = viewModel as? ImportMagicTokenCardRowViewModel {
			vm.subscribeBuilding { [weak self] building in
				guard let strongSelf = self else { return }
				strongSelf.categoryLabel.text = building
			}

			vm.subscribeLocality { [weak self] locality in
				guard let strongSelf = self else { return }
				strongSelf.cityLabel.text = ", \(locality)"
			}

			vm.subscribeExpired { [weak self] expired in
				guard let strongSelf = self else { return }
				strongSelf.teamsLabel.text = expired
			}

			vm.subscribeStreetStateCountry { [weak self] streetStateCountry in
				guard let strongSelf = self else { return }
				strongSelf.venueLabel.text = streetStateCountry
			}
		}
		nameWebView.loadHTMLString(tbmlNameHtmlString, baseURL: nil)
		introductionWebView.loadHTMLString(tbmlIntroductionHtmlString, baseURL: nil)
		instructionsWebView.loadHTMLString(tbmlInstructionHtmlString, baseURL: nil)

		adjustmentsToHandleWhenCategoryLabelTextIsTooLong()
	}

	private func adjustmentsToHandleWhenCategoryLabelTextIsTooLong() {
		tokenCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		categoryLabel.adjustsFontSizeToFitWidth = true
	}
}

//hhh should move this
extension TokenCardRowView {
	var tbmlNameHtmlString: String {
		let xmlHandler = XMLHandler(contract: "0xd2a0ddf0f4d7876303a784cfadd8f95ec1fb791c")
//		return xmlHandler.nameHtmlString
		let html = """
				   <html>
				   <head>
				   <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
				   </head>
				   \(xmlHandler.nameHtmlString)
				   </html>
				   """
		return html
	}

	var tbmlIntroductionHtmlString: String {
		let xmlHandler = XMLHandler(contract: "0xd2a0ddf0f4d7876303a784cfadd8f95ec1fb791c")
//		return xmlHandler.introductionHtmlString
		let html = """
				   <html>
				   <head>
				   <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
				   </head>
				   \(xmlHandler.introductionHtmlString)
				   </html>
				   """
		return html
	}

	var tbmlInstructionHtmlString: String {
        let xmlHandler = XMLHandler(contract: "0xd2a0ddf0f4d7876303a784cfadd8f95ec1fb791c")
//		return xmlHandler.instructionsHtmlString
		let html = """
				   <html>
				   <head>
				   <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
				   </head>
				   \(xmlHandler.instructionsHtmlString)
				   </html>
				   """
		return html
	}
}

extension TokenCardRowView: TokenRowView {
	func configure(tokenHolder: TokenHolder) {
		configure(viewModel: TokenCardRowViewModel(tokenHolder: tokenHolder))
	}
}
