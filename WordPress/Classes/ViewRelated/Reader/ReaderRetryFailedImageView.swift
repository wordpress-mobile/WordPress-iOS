//
//  ReaderRetryFailedImageView.swift
//  WordPress
//
//  Created by Paul Von Schrottky on 10/5/19.
//  Copyright © 2019 WordPress. All rights reserved.
//

import UIKit
import Gridicons

protocol ReaderRetryFailedImageDelegate: AnyObject {
    func didTapRetry()
}

class ReaderRetryFailedImageView: UIView {

    private class LinkTextView: UITextView {
        override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
            return []
        }

        override func caretRect(for position: UITextPosition) -> CGRect {
            CGRect.zero.offsetBy(dx: .greatestFiniteMagnitude, dy: .greatestFiniteMagnitude)
        }
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 10
        return stackView
    }()

    private let imageView: UIImageView = {
        let iconImage = Gridicon.iconOfType(.imageRemove)
        let imageView = UIImageView(image: iconImage.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = UIColor.textSubtle
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textView: LinkTextView = {
        let textView = LinkTextView()
        textView.textAlignment = .center
        textView.textDragInteraction?.isEnabled = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()

    private let attributedString: NSAttributedString = {
        let mutableAttributedString = NSMutableAttributedString()

        let textLocalizedString = NSLocalizedString("Image not loaded.", comment: "Message displayed in image area when a site image fails to load.")
        mutableAttributedString.append(NSAttributedString(string: textLocalizedString, attributes: WPStyleGuide.readerDetailAttributesForRetryText()))

        let singleSpaceString = " "
        mutableAttributedString.append(NSAttributedString(string: singleSpaceString))

        let buttonLocalizedString = NSLocalizedString("Retry", comment: "Retry button title in image area when a site image fails to load.")
        mutableAttributedString.append(NSAttributedString(string: buttonLocalizedString, attributes: WPStyleGuide.readerDetailAttributesForRetryButton()))

        return mutableAttributedString
    }()

    weak var delegate: ReaderRetryFailedImageDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .retryBackground

        textView.delegate = self
        textView.attributedText = attributedString

        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)

        translatesAutoresizingMaskIntoConstraints = false
        stackView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor).isActive = true
        stackView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReaderRetryFailedImageView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction, URL.scheme == "tap" else {
            return false
        }
        delegate?.didTapRetry()
        return false
    }
}
