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
    
    fileprivate var viewHeight : CGFloat

    var contentURL: URL?
    var linkURL: URL?

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
        layout.footerReferenceSize = CGSize(width: frame.width, height: 20.0)
        
        viewHeight = frame.height

        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)

        super.init(frame: frame)

        sharedSetup()

        addSubview(collectionView)
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
        collectionView.clipsToBounds = true

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true


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
                imageSource.fetchImage(for: url, with: maxDisplaySize, indexPath: indexPath, isPrivate: false)
            }

            let media = GalleryMedia(cell: cell, attachment: attachment)
            mediaArray.append(media)
        }

        return cell
    }

}

extension WPRichTextGallery: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rightInset = CGFloat(8.0)
        let rightExtraContent = CGFloat(8.0)

        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width - (rightInset + rightExtraContent) : 0
        let height = collectionView.bounds.height > 0 ? collectionView.bounds.height : viewHeight

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        handleGalleryTapped?(indexPath.row, imageAttachments)
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
