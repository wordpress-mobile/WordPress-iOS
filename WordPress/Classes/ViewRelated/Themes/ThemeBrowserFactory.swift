import Foundation

class ThemeBrowserFactory : NSObject {
    
    private var storyboard : UIStoryboard!
    
    override init() {
        super.init()
        
        storyboard = UIStoryboard(name: "ThemeBrowser", bundle: nil)
    }
    
    func instantiateThemeBrowserViewControllerWithBlog(blog: Blog) -> ThemeBrowserViewController {
        let viewController = storyboard.instantiateInitialViewController() as! ThemeBrowserViewController
        
        viewController.blog = blog
        
        return viewController
    }
}
