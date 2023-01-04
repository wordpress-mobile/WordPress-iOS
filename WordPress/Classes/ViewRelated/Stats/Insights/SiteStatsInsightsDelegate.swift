import Foundation

@objc protocol SiteStatsInsightsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func showCreatePost()
    @objc optional func showShareForPost(postID: NSNumber, fromView: UIView)
    @objc optional func showPostingActivityDetails()
    @objc optional func tabbedTotalsCellUpdated()
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func customizeDismissButtonTapped()
    @objc optional func customizeTryButtonTapped()
    @objc optional func growAudienceDismissButtonTapped(_ hintType: GrowAudienceCell.HintType)
    @objc optional func growAudienceEnablePostSharingButtonTapped()
    @objc optional func growAudienceBloggingRemindersButtonTapped()
    @objc optional func growAudienceReaderDiscoverButtonTapped()
    @objc optional func showAddInsight()
    @objc optional func addInsightSelected(_ insight: StatSection)
    @objc optional func addInsightDismissed()
    @objc optional func manageInsightSelected(_ insight: StatSection, fromButton: UIButton)
}
