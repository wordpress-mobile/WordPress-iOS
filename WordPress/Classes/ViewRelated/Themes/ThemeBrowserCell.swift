import Foundation

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Properties
    
    private var theme : Theme!
    
    // MARK: - Additional initialization
    
    public func configureWithTheme(theme: Theme) {
        self.theme = theme;
    }
}