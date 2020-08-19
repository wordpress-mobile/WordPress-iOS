
import UIKit

/// UIViewController for the What's New - Feature Announcements scene
class WhatIsNewViewController: UIViewController {

    private lazy var whatIsNewView: UIView = {
        WhatIsNewView()
    }()

    override func loadView() {
        self.view = whatIsNewView
    }
}

/// The view that gets assigned to WhatIsNewViewController at load time
class WhatIsNewView: UIView {

    lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.titleFont = Constants.continueButtonFont
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Continue",
                                          comment: "Title for the continue button in the What's New modal"), for: .normal)
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .basicBackground
        addSubview(continueButton)

        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: continueButton.leadingAnchor, constant: -Constants.continueButtonInset),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: Constants.continueButtonInset),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: Constants.continueButtonInset),
            continueButton.heightAnchor.constraint(equalToConstant: Constants.continueButtonHeight)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    @objc private func continueButtonTapped() {
        // TODO - WHATSNEW: this will likely need to be changed to not rely on the responder chain
        guard let controller = self.next as? UIViewController else {
            return
        }
        controller.dismiss(animated: true)
    }
}


private extension WhatIsNewView {

    enum Constants {
        static let continueButtonHeight: CGFloat = 48
        static let continueButtonInset: CGFloat = 16
        static let continueButtonFont = UIFont.systemFont(ofSize: 22, weight: .medium)
    }
}
