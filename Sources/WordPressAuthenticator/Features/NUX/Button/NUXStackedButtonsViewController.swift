import UIKit
import WordPressShared

struct StackedButton {
    enum StackView {
        case top
        case bottom
    }

    let stackView: StackView
    let style: NUXButtonStyle?

    var config: NUXButtonConfig {
        NUXButtonConfig(title: title, isPrimary: isPrimary, configureBodyFontForTitle: configureBodyFontForTitle, accessibilityIdentifier: accessibilityIdentifier, callback: onTap)
    }

    // MARK: Private properties
    private let title: String
    private let isPrimary: Bool
    private let configureBodyFontForTitle: Bool
    private let accessibilityIdentifier: String?
    private let onTap: NUXButtonConfig.CallBackType

    init(stackView: StackView = .top,
         title: String,
         isPrimary: Bool = false,
         configureBodyFontForTitle: Bool = false,
         accessibilityIdentifier: String? = nil,
         style: NUXButtonStyle?,
         onTap: @escaping NUXButtonConfig.CallBackType) {
        self.stackView = stackView
        self.title = title
        self.isPrimary = isPrimary
        self.configureBodyFontForTitle = configureBodyFontForTitle
        self.accessibilityIdentifier = accessibilityIdentifier
        self.style = style
        self.onTap = onTap
    }

    // MARK: Initializers

    /// Initializes a new StackedButton instance using the properties from the provided `StackedButton` and the provided `stackView`
    ///
    ///  Used to copy properties of a StackedButton and just change the stackView placement
    ///
    /// - Parameters:
    ///   - using: StackedButton to be copied. (Except the `stackView` property)
    ///   - stackView: StackView placement of the new StackedButton
    init(using: StackedButton,
         stackView: StackView) {
        self.init(stackView: stackView,
                  title: using.title,
                  isPrimary: using.isPrimary,
                  configureBodyFontForTitle: using.configureBodyFontForTitle,
                  accessibilityIdentifier: using.accessibilityIdentifier,
                  style: using.style,
                  onTap: using.onTap)
    }
}

/// Used to create two stack views of NUXButtons optionally divided by a OR divider
///
/// Created as a replacement for NUXButtonViewController
///
open class NUXStackedButtonsViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet private weak var buttonHolder: UIView?

    // Stack view
    @IBOutlet private var topStackView: UIStackView?
    @IBOutlet private var bottomStackView: UIStackView?

    // Divider line
    @IBOutlet private weak var leadingDividerLine: UIView!
    @IBOutlet private weak var leadingDividerLineHeight: NSLayoutConstraint!
    @IBOutlet private weak var dividerStackView: UIStackView!
    @IBOutlet private weak var dividerLabel: UILabel!
    @IBOutlet private weak var trailingDividerLine: UIView!
    @IBOutlet private weak var trailingDividerLineHeight: NSLayoutConstraint!

    // Shadow
    @IBOutlet private weak var shadowView: UIImageView?
    @IBOutlet private var shadowViewEdgeConstraints: [NSLayoutConstraint]!

    /// Used to constrain the shadow view outside of the
    /// bounds of this view controller.
    weak var shadowLayoutGuide: UILayoutGuide? {
        didSet {
            updateShadowViewEdgeConstraints()
        }
    }

    var backgroundColor: UIColor?
    private var showDivider = true
    private var buttons: [NUXButton] = []

    private let style = WordPressAuthenticator.shared.style

    private var buttonConfigs = [StackedButton]()

    // MARK: - View
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false

        shadowView?.image = style.buttonViewTopShadowImage
        configureDivider()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadViews()

        buttonHolder?.backgroundColor = backgroundColor
    }

    // MARK: public API
    func setUpButtons(using config: [StackedButton], showDivider: Bool) {
        self.buttonConfigs = config
        self.showDivider = showDivider
        createButtons()
    }

    func hideShadowView() {
        shadowView?.isHidden = true
    }
}

// MARK: Helpers
//
private extension NUXStackedButtonsViewController {
    @objc func handleTap(_ sender: NUXButton) {
        guard let index = buttons.firstIndex(of: sender),
              let callback = buttonConfigs[index].config.callback else {
            return
        }

        callback()
    }

    func reloadViews() {
        for (index, button) in buttons.enumerated() {
            button.configure(withConfig: buttonConfigs[index].config, and: buttonConfigs[index].style)
            button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }
        dividerStackView.isHidden = !showDivider
    }

    func createButtons() {
        buttons = []
        topStackView?.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        bottomStackView?.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for config in buttonConfigs {
            let button = NUXButton()
            switch config.stackView {
            case .top:
                topStackView?.addArrangedSubview(button)
            case .bottom:
                bottomStackView?.addArrangedSubview(button)
            }
            button.configure(withConfig: config.config, and: config.style)
            buttons.append(button)
        }
    }

    func configureDivider() {
        guard showDivider else {
            return dividerStackView.isHidden = true
        }

        leadingDividerLine.backgroundColor = style.orDividerSeparatorColor
        leadingDividerLineHeight.constant = WPStyleGuide.hairlineBorderWidth
        trailingDividerLine.backgroundColor = style.orDividerSeparatorColor
        trailingDividerLineHeight.constant = WPStyleGuide.hairlineBorderWidth
        dividerLabel.textColor = style.orDividerTextColor
        dividerLabel.text = NSLocalizedString("Or", comment: "Divider on initial auth view separating auth options.").localizedUppercase
    }

    func updateShadowViewEdgeConstraints() {
        guard let layoutGuide = shadowLayoutGuide,
              let shadowView else {
            return
        }

        NSLayoutConstraint.deactivate(shadowViewEdgeConstraints)
        shadowView.translatesAutoresizingMaskIntoConstraints = false

        shadowViewEdgeConstraints = [
            layoutGuide.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
        ]

        NSLayoutConstraint.activate(shadowViewEdgeConstraints)
    }

    // MARK: - Dynamic type
    func didChangePreferredContentSize() {
        reloadViews()
    }
}

extension NUXStackedButtonsViewController {
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}

extension NUXStackedButtonsViewController {

    /// Sets the parentViewControlleras the receiver instance's container. Plus: the containerView will also get the receiver's
    /// view, attached to it's edges. This is effectively analog to using an Embed Segue with the NUXButtonViewController.
    ///
    public func move(to parentViewController: UIViewController, into containerView: UIView) {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        containerView.pinSubviewToAllEdges(view)

        willMove(toParent: parentViewController)
        parentViewController.addChild(self)
        didMove(toParent: parentViewController)
    }

    /// Returns a new NUXButtonViewController Instance
    ///
    public class func instance() -> NUXStackedButtonsViewController {
        guard let buttonViewController = Storyboard.nuxButtonView.instantiateViewController(ofClass: NUXStackedButtonsViewController.self) else {
            fatalError("Cannot instantiate initial NUXStackedButtonsViewController from NUXButtonView.storyboard")
        }

        return buttonViewController
    }
}

private extension NUXButton {
    func configure(withConfig buttonConfig: NUXButtonConfig?, and style: NUXButtonStyle?) {
        guard let buttonConfig else {
            isHidden = true
            return
        }

        if let attributedTitle = buttonConfig.attributedTitle {
            setAttributedTitle(attributedTitle, for: .normal)
        } else {
            setTitle(buttonConfig.title, for: .normal)
        }

        socialService = buttonConfig.socialService
        accessibilityIdentifier = buttonConfig.accessibilityIdentifier ?? "\(buttonConfig.title ?? "") Button"
        isPrimary = buttonConfig.isPrimary

        if buttonConfig.configureBodyFontForTitle == true {
            customizeFont(WPStyleGuide.mediumWeightFont(forStyle: .body))
        }

        buttonStyle = style

        isHidden = false
    }
}
