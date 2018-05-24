
import UIKit

extension WPStyleGuide {
    static func styleProgressViewWhite(_ progressView: CircularProgressView) {
        progressView.backgroundColor = .clear
    }

    static func styleProgressViewForMediaCell(_ progressView: CircularProgressView) {
        progressView.backgroundColor = WPStyleGuide.darkGrey()
        progressView.retryView.tintColor = .white
    }

    @objc(addErrorViewToProgressView:)
    static func addErrorView(to progressView: CircularProgressView) {
        let errorView = UIImageView(image: #imageLiteral(resourceName: "hud_error").withRenderingMode(.alwaysTemplate))
        errorView.tintColor = WPStyleGuide.errorRed()
        errorView.translatesAutoresizingMaskIntoConstraints = false
        progressView.addErrorView(errorView)
    }
}
