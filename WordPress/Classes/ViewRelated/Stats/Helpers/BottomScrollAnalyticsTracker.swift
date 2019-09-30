
import Foundation

// MARK: - BottomScrollAnalyticsTracker

final class BottomScrollAnalyticsTracker: NSObject {

    private func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }

    private func trackScrollToBottomEvent() {
        captureAnalyticsEvent(.statsScrolledToBottom)
    }
}

// MARK: - UIScrollViewDelegate

extension BottomScrollAnalyticsTracker: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        let targetOffsetY = Int(targetContentOffset.pointee.y)

        let scrollViewContentHeight = scrollView.contentSize.height
        let visibleScrollViewHeight = scrollView.bounds.height
        let effectiveScrollViewHeight = Int(scrollViewContentHeight - visibleScrollViewHeight)

        if targetOffsetY >= effectiveScrollViewHeight {
            trackScrollToBottomEvent()
        }
    }
}
