import Foundation


public class NoteSettingsTitleTableViewCell : WPTableViewCell
{
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(self)
    }
}
