//
//  WPRichTextGalleryLayout.swift
//  WordPress
//
//  Created by Jeff Jacka on 11/11/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class WPRichTextGalleryLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        
        collectionView?.backgroundColor = .clear
        
        scrollDirection = .horizontal
        
    }
    
    fileprivate var contentHeight: CGFloat = 150.0
    
    fileprivate var contentWidth : CGFloat {
        
        guard let collectionView = collectionView else {
            return 0
        }
        
        let rightInset = CGFloat(8.0)
        let rightExtraContent = CGFloat(8.0)
        
        return collectionView.bounds.width - (rightInset + rightExtraContent)
    }
    
    override var collectionViewContentSize: CGSize {
        let width = contentWidth
        let height = contentHeight
        
        print("gallery layout cell height\(height), width: \(width)")
        
        return CGSize(width: width, height: height)
    }
    
}
