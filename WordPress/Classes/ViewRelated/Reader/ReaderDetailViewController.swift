import Foundation

public class ReaderDetailViewController : UIViewController, UIScrollViewDelegate
{
    // MARK: - Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!

    private weak var detailView: ReaderDetailView!

    public var readerPost: ReaderPost?


    // MARK: - Convenience Factories

    /**
     Convenience method for instantiating an instance of ReaderListViewController
     for a particular topic.

     @param topic The reader topic for the list.

     @return A ReaderListViewController instance.
     */
    public class func controllerWithPost(post:ReaderPost) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderDetailViewController") as! ReaderDetailViewController
        controller.readerPost = post

        return controller
    }

    public class func controllerWithPostID(postID:NSNumber, siteID:NSNumber) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderDetailViewController") as! ReaderDetailViewController
        controller.setupWithPostID(postID, siteID:siteID)

        return controller
    }


    // MARK: - LifeCycle Methods


    // MARK: - Setup


    public func setupWithPostID(postID:NSNumber, siteID:NSNumber) {

    }


    // MARK: - Configuration



}
