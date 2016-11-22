import UIKit

class ReaderCommentCell : UITableViewCell
{
    var enableLoggedInFeatures = false
    var shouldShowReply = false

    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var authorButton: UIButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var textView: WPRichContentView!
    @IBOutlet var replyButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var actionBar: UIStackView!

    weak var delegate: AnyObject?
    var comment: Comment?


    // MARK: - Configuration


    func configureCell(comment: Comment) {
        self.comment = comment

        configureAvatar()
        configureAuthorButton()
        configureTime()
        configureText()
        configureActionBar()
    }


    func configureAvatar() {

    }


    func configureAuthorButton() {

    }

    func configureTime() {

    }

    func configureText() {

    }


    func configureActionBar() {

    }



    // MARK: - Actions


    @IBAction func handleAuthorTapped(sender: UIButton) {
        
    }

    @IBAction func handleReplyTapped(sender: UIButton) {

    }

    @IBAction func handleLikeTapped(sender: UIButton) {

    }

}
