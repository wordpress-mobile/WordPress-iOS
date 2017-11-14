//
//  WPRichTextGallery.swift
//  WordPress
//
//  Created by Jeff Jacka on 11/11/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit
import WordPressShared

class WPRichTextGallery: UIView, WPRichTextMediaAttachment {

    fileprivate let galleryCellIdentifier = "ReaderGalleryCell"

    fileprivate var viewHeight: CGFloat

    var isPrivate : Bool = false
    var contentURL: URL?
    var linkURL: URL?
    
    var cellSize : CGFloat = 10

    /// Used to load images for attachments.
    ///
    lazy var imageSource: WPTableImageSource = {
        let source = WPTableImageSource(maxSize: self.maxDisplaySize)
        source?.delegate = self
        source?.forceLargerSizeWhenFetching = false
        source?.photonQuality = 65
        return source!
    }()

    fileprivate var collectionView: UICollectionView
    var captionLabel : UILabel?
    var pageLabel : UILabel?

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

    var imageAttachments = [WPTextAttachment]()
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

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8.0
        viewHeight = frame.height

        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        
        let captionLabel = UILabel()
        self.captionLabel = captionLabel
        WPStyleGuide.applyReaderCardSummaryLabelStyle(captionLabel)
        captionLabel.text = ""
        
        let pageLabel = UILabel()
        self.pageLabel = pageLabel
        WPStyleGuide.applyReaderCardSummaryLabelStyle(pageLabel)
        pageLabel.text = ""

        super.init(frame: frame)
        
        let footerStack = UIStackView(arrangedSubviews: [captionLabel, pageLabel])
        footerStack.translatesAutoresizingMaskIntoConstraints = false

        sharedSetup()

        addSubview(collectionView)
        addSubview(footerStack)
        
        collectionView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: footerStack.topAnchor).isActive = true
        
        footerStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        footerStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        footerStack.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        footerStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    }

    required public init?(coder aDecoder: NSCoder) {

        collectionView = aDecoder.decodeObject(forKey: UICollectionView.classNameWithoutNamespaces()) as! UICollectionView
        contentURL = aDecoder.decodeObject(forKey: "contentURL") as! URL?
        linkURL = aDecoder.decodeObject(forKey: "linkURL") as! URL?
        viewHeight = aDecoder.decodeObject(forKey: "viewHeight") as! CGFloat

        super.init(coder: aDecoder)

        sharedSetup()
    }

    fileprivate func sharedSetup() {

        let galleryXib = UINib(nibName: "ReaderGalleryCell", bundle: Bundle.main)

        collectionView.register(galleryXib, forCellWithReuseIdentifier: galleryCellIdentifier)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.showsHorizontalScrollIndicator = false

    }

    override open func encode(with aCoder: NSCoder) {

        aCoder.encode(collectionView, forKey: UICollectionView.classNameWithoutNamespaces())

        if let url = contentURL {
            aCoder.encode(url, forKey: "contentURL")
        }

        if let url = linkURL {
            aCoder.encode(url, forKey: "linkURL")
        }

        aCoder.encode(viewHeight, forKey: "viewHeight")

        super.encode(with: aCoder)
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
            if let cachedImage = imageSource.image(for: url, with: maxDisplaySize) {
                cell.galleryImageView.image = cachedImage
                attachment.maxSize = cachedImage.size
            } else {
                let index = mediaArray.count
                let indexPath = IndexPath(row: index, section: 1)
                imageSource.fetchImage(for: url, with: maxDisplaySize, indexPath: indexPath, isPrivate: isPrivate)
            }

            let media = GalleryMedia(cell: cell, attachment: attachment)
            mediaArray.append(media)
        }

        return cell
    }

}

extension WPRichTextGallery: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        let leadingEdge = frame.minX - (superview?.frame.minX ?? 0)
        let superWidth = superview?.frame.width ?? 0
        let cellWidth = superWidth - (2 * leadingEdge)
        
        cellSize = cellWidth
        
        let height = collectionView.bounds.height > 0 ? collectionView.bounds.height : viewHeight

        return CGSize(width: cellWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        handleGalleryTapped?(indexPath.row, imageAttachments)
    }
    
    /* In case the user scrolls for a long swipe, the scroll view should animate to the nearest page when the scrollview decelerated. */
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollToPage(scrollView, withVelocity: velocity)
    }
    
    func scrollToPage(_ scrollView: UIScrollView, withVelocity velocity: CGPoint) {
        let cellWidth: CGFloat = cellSize
        let cellPadding: CGFloat = 8
        
        var page: Int = Int((scrollView.contentOffset.x - cellWidth / 2) / (cellWidth + cellPadding) + 1)
        if velocity.x > 0 {
            page += 1
        }
        if velocity.x < 0 {
            page -= 1
        }
        page = max(page, 0)
        let newOffset: CGFloat = CGFloat(page) * (cellWidth + cellPadding)
        
        scrollView.setContentOffset(CGPoint(x:newOffset, y:0), animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToPage(scrollView, withVelocity: CGPoint(x:0, y:0))
        
        //Thanks Stackoverflow
        ///https://stackoverflow.com/a/36190887
        
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        if let attachment = imageAttachments[safe: page] {
            let title = attachment.attributes?["title"]
            captionLabel?.text = title
        }
        
        pageLabel?.text = "\(page + 1)/\(imageAttachments.count)"
        
    }

}

extension WPRichTextGallery: WPTableImageSourceDelegate {

    func tableImageSource(_ tableImageSource: WPTableImageSource!, imageReady image: UIImage!, for indexPath: IndexPath!) {
        let richMedia = mediaArray[indexPath.row]

        richMedia.cell.galleryImageView.image = image
        richMedia.attachment.maxSize = image.size

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
