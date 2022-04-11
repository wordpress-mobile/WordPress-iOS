//
//  DashboardPostsListCardCell.swift
//  WordPress
//
//  Created by Hassaan El-Garem on 11/04/2022.
//  Copyright © 2022 WordPress. All rights reserved.
//

import UIKit

class DashboardPostsListCardCell: UICollectionViewCell, Reusable {

    // MARK: Private Variables

    private var viewModel: PostsCardViewModel?
    private var frameView: BlogDashboardCardFrameView?
    private var blog: Blog?

    /// The VC presenting this cell
    private weak var viewController: UIViewController?

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Helpers

    private func commonInit() {
        addSubviews()
    }

    private func addSubviews() {
        let frameView = BlogDashboardCardFrameView()
        frameView.icon = UIImage.gridicon(.posts, size: Constants.iconSize)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        self.frameView = frameView

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: Constants.constraintPriority)
    }

}

// MARK: BlogDashboardCardConfigurable

extension DashboardPostsListCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?, cardType: DashboardCard) {
        self.blog = blog
        self.viewController = viewController

        switch cardType {
        case .draftPosts:
            configureDraftsList(blog: blog)
        case .scheduledPosts:
            configureScheduledList(blog: blog)
        default:
            return
        }
    }

    private func configureDraftsList(blog: Blog) {
        frameView?.title = Strings.draftsTitle
        frameView?.onHeaderTap = { [weak self] in
            self?.presentPostList(with: .draft)
        }
    }

    private func configureScheduledList(blog: Blog) {
        frameView?.title = Strings.scheduledTitle
        frameView?.onHeaderTap = { [weak self] in
            self?.presentPostList(with: .scheduled)
        }
    }

    private func presentPostList(with status: BasePost.Status) {
        guard let blog = blog, let viewController = viewController else {
            return
        }

        PostListViewController.showForBlog(blog, from: viewController, withPostStatus: status)
        WPAppAnalytics.track(.openedPosts, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "posts_card"], with: blog)
    }

}

// MARK: Constants

private extension DashboardPostsListCardCell {

    private enum Strings {
        static let draftsTitle = NSLocalizedString("Work on a draft post", comment: "Title for the card displaying draft posts.")
        static let scheduledTitle = NSLocalizedString("Upcoming scheduled posts", comment: "Title for the card displaying upcoming scheduled posts.")
    }

    enum Constants {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
    }
}
