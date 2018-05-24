
import UIKit

extension WPStyleGuide {
    static func styleProgressViewWhite(_ progressView: CircularProgressView) {
        progressView.loaderAppearance = ProgressIndicatorView.Appearance(lineColor: WPStyleGuide.lightBlue())
        progressView.backgroundColor = .clear
    }

    static func styleProgressViewForMediaCell(_ progressView: CircularProgressView) {
        progressView.backgroundColor = WPStyleGuide.darkGrey()
        let appearance = ProgressIndicatorView.Appearance(lineColor: .white, trackColor: WPStyleGuide.grey())
        progressView.loaderAppearance = appearance
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
