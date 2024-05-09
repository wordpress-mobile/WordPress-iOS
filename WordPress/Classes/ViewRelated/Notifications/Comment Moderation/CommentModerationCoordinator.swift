import UIKit
import WordPressUI
import SwiftUI

final class CommentModerationCoordinator {
    private unowned let commentDetailViewController: CommentDetailViewController

    init(commentDetailViewController: CommentDetailViewController) {
        self.commentDetailViewController = commentDetailViewController
    }

    func didTapMoreOptions() {
        commentDetailViewController.presentChangeStatusSheet()
    }
}
