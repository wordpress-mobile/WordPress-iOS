import Foundation
import WordPressKit

extension RemoteSiteDesign: Thumbnail {
    var urlDesktop: String? { screenshot }
    var urlTablet: String? { tabletScreenshot }
    var urlMobile: String? { mobileScreenshot}
}
