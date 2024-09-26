import UIKit

extension UIView {

    func getHorizontalMargin(compactMargin: CGFloat = 0.0) -> CGFloat {
        guard traitCollection.verticalSizeClass == .regular,
              traitCollection.horizontalSizeClass == .regular else {
                  return compactMargin
              }

        let isLandscape = UIDevice.current.orientation.isLandscape
        let multiplier: CGFloat = isLandscape ? .ipadLandscape : .ipadPortrait

        return frame.width * multiplier
    }

}

private extension CGFloat {

    static let ipadPortrait: CGFloat = 0.1667
    static let ipadLandscape: CGFloat = 0.25

}
