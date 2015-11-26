import Foundation


extension BlogSettings
{
    public struct Threading
    {
        public static let DepthDisabled = 0
        
        public static let DepthMinimum  = 2
        
        public static let DepthMaximum  = 10
        
        public static var DepthValues : [Int] {
            return DepthLevels.keys.sort()
        }
        
        public static var DepthTitles : [String] {
            return DepthValues.map { DepthLevels[$0]! }
        }
        
        public static var DepthLevels : [Int : String] {
            let posfixText = NSLocalizedString(" levels", comment: "Threading Levels. A numeric value will be prepended")
            var optionsMap = [Int : String]()
            
            optionsMap[DepthDisabled] = NSLocalizedString("Disabled", comment: "")
            
            for currentLevel in DepthMinimum...DepthMaximum {
                let level = NSNumberFormatter.localizedStringFromNumber(currentLevel, numberStyle: .SpellOutStyle)
                optionsMap[currentLevel] = level.capitalizedString + posfixText
            }
            
            return optionsMap
        }
    }
}
