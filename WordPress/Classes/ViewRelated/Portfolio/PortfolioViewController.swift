    import UIKit
    import WordPressKit
    
    class PortfolioViewController: UITableViewController, UIViewControllerRestoration {
        fileprivate static let restorationIdentifier = "PortfolioViewController"
        fileprivate static let portfolioViewControllerRestorationKey = "PortfolioViewControllerRestorationKey"
        fileprivate static let projectCellIdentifier = "ProjectCellIdentifier"
        fileprivate static let projectCellNibName = "ProjectTableViewCell"
        fileprivate static let restoreProjectCellIdentifier = "RestoreProjectCellIdentifier"
        fileprivate static let restoreProjectCellNibName = "RestoreProjectTableViewCell"
        fileprivate static let projectCellEstimatedRowHeight = CGFloat(54.0)
        var viewModel: PortfolioViewModel?
        var noResultsView: WPNoResultsView?
        let mainContext = ContextManager.sharedInstance().mainContext
        let postService: PostService
        var postServiceRemote: PostServiceRemoteREST?
        
        init(blog: Blog) {
            self.postService = PostService(managedObjectContext: mainContext)
            if
                let dotComID = blog.dotComID,
                let wordPressApi = blog.wordPressComRestApi() {
                self.postServiceRemote = PostServiceRemoteREST(wordPressComRestApi: wordPressApi, siteID: dotComID)
            }
            super.init(nibName: nil, bundle: nil)
            // super.restorationIdentifier = PortfolioViewController.restorationIdentifier
            // restorationClass = PortfolioViewController.self
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            //  super.tableViewController = UITableViewController(style: .plain)
            configureTableView()
            postServiceRemote?.getPostsOfType("jetpack-portfolio", options: [:], success: { [weak self] remotePosts in
                if let posts = remotePosts,
                    posts.count > 0 {
                    self?.viewModel = PortfolioViewModel(posts: posts)
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                } else {
                    self?.addNoResultsView()
                }
                
            }) { error in
                DDLogError(String(describing: error))
            }
        }
        
        private func addNoResultsView() {
            guard let noResultsView = WPNoResultsView(title: "No Available Projects",
                                                      message: nil,
                                                      accessoryView: UIImageView(image: UIImage(named: "theme-empty-results")),
                                                      buttonTitle: nil) else { return }
            
            view.addSubview(noResultsView)
            noResultsView.centerInSuperview()
            
            noResultsView.delegate = self
            
            self.noResultsView = noResultsView
        }
        
        func configureTableView() {
            tableView.accessibilityIdentifier = "PortfolioTable"
            tableView.isAccessibilityElement = true
            tableView.rowHeight = PortfolioViewController.projectCellEstimatedRowHeight
            
            // Register the cells
            let pageCellNib = UINib(nibName: type(of: self).projectCellNibName, bundle: Bundle.main)
            tableView.register(pageCellNib, forCellReuseIdentifier: type(of: self).projectCellIdentifier)

            let restorePageCellNib = UINib(nibName: type(of: self).restoreProjectCellNibName, bundle: Bundle.main)
            tableView.register(restorePageCellNib, forCellReuseIdentifier: type(of: self).restoreProjectCellIdentifier)

            WPStyleGuide.configureColors(for: view, andTableView: tableView)
        }

        class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {

            let context = ContextManager.sharedInstance().mainContext

            guard let blogID = coder.decodeObject(forKey: portfolioViewControllerRestorationKey) as? String,
                let objectURL = URL(string: blogID),
                let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
                let restoredBlog = try? context.existingObject(with: objectID) as! Blog else {
    
                    return nil
            }

            return PortfolioViewController(blog: restoredBlog)
        }

        // MARK: - UIStateRestoring
        //        override func encodeRestorableState(with coder: NSCoder) {
        //            let objectString = blog?.objectID.uriRepresentation().absoluteString
        //            coder.encode(objectString, forKey: type(of: self).portfolioViewControllerRestorationKey)
        //            super.encodeRestorableState(with: coder)
        //        }
    }

    extension PortfolioViewController {
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            guard let viewModel = viewModel else { return 0 }
            return viewModel.posts.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).projectCellIdentifier, for: indexPath) as! ProjectTableViewCell
            if let post = viewModel?.posts[indexPath.row] {
                cell.configure(title: post.title, imageURLString: post.pathForDisplayImage)
            }
            return cell
        }
    }

    extension PortfolioViewController: WPNoResultsViewDelegate {

    }
