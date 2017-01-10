import UIKit

@objc open class ReaderPostCardContentLabel: UILabel {

    open override var intrinsicContentSize: CGSize {
        // HACK
        // iPhone Pluses with 3.0 render scales seem to produce fractional sizes with labels
        // that are sized via UIStackViews.
        // Ensure frames are integral and not fractional sizes, otherwise labels
        // may draw text truncated prematurely. Seems to only occur with the MerriWeather font.
        // But it is good to render integral label frames anyways.
        // Brent C. Oct/6/2016
        var size = super.intrinsicContentSize
        size.width = ceil(size.width)
        size.height = ceil(size.height) + 1.0
        return size
    }
}
