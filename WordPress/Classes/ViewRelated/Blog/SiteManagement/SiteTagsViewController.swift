//
//  SiteTagsViewController.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-11-30.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation

final class SiteTagsViewController: UITableViewController {
    private let blog: Blog
    private let tagsService: PostTagService
    
    @objc
    public init(blog: Blog, tagsService: PostTagService) {
        self.blog = blog
        self.tagsService = tagsService
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setAccessibilityIdentifier()
        applyStyleGuide()
    }
    
    private func setAccessibilityIdentifier() {
        tableView.accessibilityIdentifier = "SiteTagsList"
    }
    
    private func applyStyleGuide() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }
}
