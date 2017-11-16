import UIKit
import WordPressShared

class WPRichTextGallery: UIView, WPRichTextMediaAttachment {

    /// MARK - Constants
    ///

    fileprivate let galleryCellIdentifier = "ReaderGalleryCell"
    fileprivate let contentUrlKey = "contentUrl"
    fileprivate let linkUrlKey = "linkUrl"
    fileprivate let viewHeightKey = "viewHeight"

    fileprivate var viewHeight: CGFloat

    var isPrivate = false
    var contentURL: URL?
    var linkURL: URL?

    /// Default cell size, will be recalculated as page is laid out
    ///
    var cellWidth: CGFloat = 1.0
    let cellPadding: CGFloat = 8.0

    /// Used to load images for attachments.
    ///
    lazy var imageSource: WPTableImageSource? = {
        let source = WPTableImageSource(maxSize: self.maxDisplaySize)
        source?.delegate = self
        source?.forceLargerSizeWhenFetching = false
        source?.photonQuality = 65
        return source
    }()

    fileprivate var collectionView: UICollectionView
    fileprivate var footerStack: UIStackView

    var captionLabel: UILabel?
    var pageLabel: UILabel?

    /// Used to keep references to image attachments.
    ///
    fileprivate var mediaArray = [GalleryMedia]()

    /// The maximum size for images.
    ///
    lazy var maxDisplaySize: CGSize = {
        let bounds = UIScreen.main.bounds
        let side = max(bounds.size.width, bounds.size.height)
        return CGSize(width: side, height: side)
    }()

    let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8.0
        layout.minimumLineSpacing = 8.0
        return layout
    }()

    var imageAttachments = [WPTextAttachment]() {
        didSet {
            if imageAttachments.count > 0 {
                //Set Up Initial Text
                let pageLabels = labelForAttachment(atIndex: 0)
                captionLabel?.text = pageLabels.title
                pageLabel?.text = pageLabels.pageNumber
            }
        }
    }
    var handleGalleryTapped : ((_ selectedIndex: Int, _ galleryImages: [WPTextAttachment]) -> ())?

    override open var frame: CGRect {
        didSet {
            // If Voice Over is enabled, the OS will query for the accessibilityPath
            // to know what region of the screen to highlight. If the path is nil
            // the OS should fall back to computing based on the frame but this
            // may be bugged. Setting the accessibilityPath avoids a crash.
            accessibilityPath = UIBezierPath(rect: frame)
        }
    }


    // MARK: Lifecycle

    override init(frame: CGRect) {

        viewHeight = frame.height

        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)

        let footerStack = UIStackView()
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        self.footerStack = footerStack

        super.init(frame: frame)

        addSubview(collectionView)
        addSubview(footerStack)

        sharedSetup()
    }

    required public init?(coder aDecoder: NSCoder) {

        collectionView = aDecoder.decodeObject(forKey: UICollectionView.classNameWithoutNamespaces()) as! UICollectionView
        footerStack = aDecoder.decodeObject(forKey: UIStackView.classNameWithoutNamespaces()) as! UIStackView
        contentURL = aDecoder.decodeObject(forKey: contentUrlKey) as? URL
        linkURL = aDecoder.decodeObject(forKey: linkUrlKey) as? URL
        viewHeight = aDecoder.decodeObject(forKey: viewHeightKey) as! CGFloat

        super.init(coder: aDecoder)

        sharedSetup()
    }
    
    override open func encode(with aCoder: NSCoder) {
        
        aCoder.encode(collectionView, forKey: UICollectionView.classNameWithoutNamespaces())
        aCoder.encode(footerStack, forKey: UIStackView.classNameWithoutNamespaces())
        
        if let url = contentURL {
            aCoder.encode(url, forKey: contentUrlKey)
        }
        
        if let url = linkURL {
            aCoder.encode(url, forKey: linkUrlKey)
        }
        
        aCoder.encode(viewHeight, forKey: viewHeightKey)
        
        super.encode(with: aCoder)
    }

    fileprivate func sharedSetup() {

        clipsToBounds = true

        setupCollectionView()
        setupLabels()
        
        collectionView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: footerStack.topAnchor).isActive = true

        footerStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        footerStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        footerStack.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
    }

    fileprivate func setupLabels() {

        let captionLabel = UILabel()
        self.captionLabel = captionLabel
        WPStyleGuide.applyPageTitleStyle(captionLabel)
        footerStack.addArrangedSubview(captionLabel)

        let pageLabel = UILabel()
        self.pageLabel = pageLabel
        WPStyleGuide.applyReaderCardSummaryLabelStyle(pageLabel)
        footerStack.addArrangedSubview(pageLabel)
    }

    fileprivate func labelForAttachment(atIndex index: Int) -> (title: String?, pageNumber: String?) {

        guard let attachment = imageAttachments[safe: index] else {
            return (nil, nil)
        }

        let imageTitle = attachment.attributes?["title"]
        let altTitle = attachment.attributes?["alt"]

        let title = imageTitle ?? altTitle
        let page = "\(index + 1)/\(imageAttachments.count)"

        return (title, page)
    }

    fileprivate func setupCollectionView() {

        let galleryXib = UINib(nibName: galleryCellIdentifier, bundle: Bundle.main)

        collectionView.register(galleryXib, forCellWithReuseIdentifier: galleryCellIdentifier)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.showsHorizontalScrollIndicator = false
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        return CGSize(width: collectionView.frame.width, height: viewHeight)
    }

    func contentRatio() -> CGFloat {
        return collectionView.frame.width / viewHeight
    }
}

extension WPRichTextGallery: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageAttachments.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: galleryCellIdentifier, for: indexPath) as! ReaderGalleryCell
        let attachment = imageAttachments[indexPath.row]

        if let url = URL(string: attachment.src) {
            if let cachedImage = imageSource?.image(for: url, with: maxDisplaySize) {
                cell.galleryImageView.image = cachedImage
                attachment.maxSize = cachedImage.size
                cell.loadingIndicator.stopAnimating()
            } else {
                let index = mediaArray.count
                let indexPath = IndexPath(row: index, section: 1)
                cell.loadingIndicator.startAnimating()
                imageSource?.fetchImage(for: url, with: maxDisplaySize, indexPath: indexPath, isPrivate: isPrivate)
            }

            let media = GalleryMedia(cell: cell, attachment: attachment)
            mediaArray.append(media)
        }

        return cell
    }

}

extension WPRichTextGallery: UICollectionViewDelegateFlowLayout {

    func setOffsetIfNeeded() {
        //TODO: Still Needs Fixing
        let leadingEdge = frame.minX - (superview?.frame.minX ?? 0)

        if leadingEdge < 16 {
            let neededOffset = 16 - leadingEdge

            collectionView.contentInset = UIEdgeInsets(top: 0, left: neededOffset, bottom: 0, right: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let leadingEdge = frame.minX - (superview?.frame.minX ?? 0)
        let superWidth = superview?.frame.width ?? 0
        let cellWidth = superWidth - (2 * leadingEdge)

        self.cellWidth = cellWidth

        let height = collectionView.bounds.height > 0 ? collectionView.bounds.height : viewHeight

        return CGSize(width: cellWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        handleGalleryTapped?(indexPath.row, imageAttachments)
    }

    /// Stackoverflow
    /// https://stackoverflow.com/a/46303794
    /// In case the user scrolls for a long swipe, the scroll view should animate to the nearest page when the scrollview decelerated.
    ///

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollToPage(scrollView, withVelocity: velocity)
    }

    func scrollToPage(_ scrollView: UIScrollView, withVelocity velocity: CGPoint) {

        var page = calculateCurrentPage(scrollView: scrollView)
        if velocity.x > 0 {
            page += 1
        }
        if velocity.x < 0 {
            page -= 1
        }
        page = max(page, 0)
        let newOffset: CGFloat = CGFloat(page) * (cellWidth + cellPadding)

        scrollView.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }

    func calculateCurrentPage(scrollView: UIScrollView) -> Int {

        let page  = Int((scrollView.contentOffset.x - cellWidth / 2) / (cellWidth + cellPadding) + 1)
        return page
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToPage(scrollView, withVelocity: CGPoint(x: 0, y: 0))

        /// Thanks Stackoverflow
        /// https://stackoverflow.com/a/36190887

        let page = calculateCurrentPage(scrollView: scrollView)

        let pageLabels = labelForAttachment(atIndex: page)
        captionLabel?.text = pageLabels.title
        pageLabel?.text = pageLabels.pageNumber
    }

}

extension WPRichTextGallery: WPTableImageSourceDelegate {

    func tableImageSource(_ tableImageSource: WPTableImageSource!, imageReady image: UIImage!, for indexPath: IndexPath!) {
        let richMedia = mediaArray[indexPath.row]

        richMedia.cell.galleryImageView.image = image
        richMedia.attachment.maxSize = image.size
        richMedia.cell.loadingIndicator.stopAnimating()

        collectionView.reloadData()
    }

    func tableImageSource(_ tableImageSource: WPTableImageSource!, imageFailedforIndexPath indexPath: IndexPath!, error: Error!) {
        let richMedia = mediaArray[indexPath.row]
        DDLogError("Error loading image: \(richMedia.attachment.src)")
        DDLogError("\(error)")
    }
}

struct GalleryMedia {
    let cell: ReaderGalleryCell
    let attachment: WPTextAttachment
}
