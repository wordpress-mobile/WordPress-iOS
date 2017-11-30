//
//  SiteTagsViewController.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-11-30.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation

final class SiteTagsViewController: UITableViewController {
    private struct TableConstants {
        static let cellIdentifier = "TagsAdminCell"
        static let numberOfSections = 1
    }
    private let blog: Blog
    private let tagsService: PostTagService
    private var tags: [PostTag] = []
    
    fileprivate let noResultsView = WPNoResultsView()
    
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
        super.viewDidLoad()
        
        setAccessibilityIdentifier()
        applyStyleGuide()
        applyTitle()
        initializeTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initializeData()
    }
    
    private func setAccessibilityIdentifier() {
        tableView.accessibilityIdentifier = "SiteTagsList"
    }
    
    private func applyStyleGuide() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }
    
    private func applyTitle() {
        title = NSLocalizedString("Tags", comment: "Label for the Tags Section in the Blog Settings")
    }
    
    private func initializeTable() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(WPTableViewCell.classForCoder(), forCellReuseIdentifier: TableConstants.cellIdentifier)
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        }
    }
    
    @objc
    private func refreshTags() {
        initializeData()
    }
    
    private func initializeData() {
        let savedTags = blog.tags?.flatMap{ return $0 as? PostTag } ?? []
        assing(savedTags)
        refreshNoResultsView()
        
        tagsService.syncTags(for: blog, success: { [weak self] tags in
            self?.assing(tags)
            self?.refreshControl?.endRefreshing()
            self?.refreshNoResultsView()
            self?.tableView.reloadData()
        }) { [weak self] error in
            self?.tagsFailedLoading(error: error)
        }
    }
    
    private func assing(_ data: [PostTag]) {
        tags = data.sorted()
    }
    
    private func refreshNoResultsView() {
        guard tags.count == 0 else {
            noResultsView.removeFromSuperview()
            return
        }
        
        noResultsView.titleText = NSLocalizedString("No Tags Yet",
            comment: "Empty state. Tags management (Settings > Writing > Tags)")
        
        if noResultsView.superview == nil {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }
    
    func tagsFailedLoading(error: Error) {
        DDLogError("Tag management. Error loading tags for \(String(describing: blog.url)): \(error)")
    }
}

extension SiteTagsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableConstants.numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableConstants.cellIdentifier, for: indexPath)

        cell.textLabel?.text = tags[indexPath.row].name
        
        return cell
    }
}
