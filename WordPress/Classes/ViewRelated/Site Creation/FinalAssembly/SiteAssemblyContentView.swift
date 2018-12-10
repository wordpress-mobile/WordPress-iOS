
import UIKit

/// This view is intended for use as the root view of `SiteAssemblyWizardContent`.
/// It manages the state transitions that occur as a site is assembled via remote service dialogue.
///
class SiteAssemblyContentView: UIView {

    // MARK: Properties

    var status: SiteAssemblyStatus = .idle {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: SiteAssemblyContentView

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [ .flexibleWidth, .flexibleHeight ]

        backgroundColor = WPStyleGuide.greyLighten30()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch status {
        case .idle:
            layoutIdle()
        case .inProgress:
            layoutIdle()
        case .failed:
            layoutFailed()
        case .succeeded:
            layoutSucceeded()
        }
    }

    // MARK: Private behavior

    private func layoutIdle() {
        debugPrint("layoutIdle")
    }

    private func layoutInProgress() {
        debugPrint("layoutInProgress")
    }

    private func layoutFailed() {
        debugPrint("layoutFailed")
    }

    private func layoutSucceeded() {
        debugPrint("layoutSucceeded")
    }
}
