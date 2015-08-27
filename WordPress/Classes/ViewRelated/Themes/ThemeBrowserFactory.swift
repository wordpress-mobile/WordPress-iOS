import Foundation

class ThemeBrowserFactory : NSObject {
    
    private var storyboard : UIStoryboard!
    
    override init() {
        super.init()
        
        storyboard = UIStoryboard(name: "ThemeBrowser", bundle: nil)
    }
    
    func instantiateThemeBrowserViewController() -> ThemeBrowserViewController {
        
        return storyboard.instantiateInitialViewController() as! ThemeBrowserViewController
    }
}