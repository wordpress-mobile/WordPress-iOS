import Foundation


extension BlogSettings
{
    /**
     *  @enum    BlogSettings.SortOrder
     *  @brief   Enumerates all of the valid Sorting Orders
     */
    public enum SortOrder : Int {
        case Ascending  = 0
        case Descending = 1
        
        var description : String {
            return SortOrder.DescriptionMap[self.rawValue]!
        }
                
        public static var SortTitles : [String] {
            return DescriptionMap.keys.map { $0.description }
        }
        
        public static var SortValues : [Int] {
            return DescriptionMap.keys.sort()
        }
        
        public static var DescriptionMap = [
            Ascending.rawValue   : NSLocalizedString("Oldest First", comment: "Sort Order"),
            Descending.rawValue  : NSLocalizedString("Newest First", comment: "Sort Order")
        ]
    }

    
    
    public struct Threading
    {
        public static let DepthDisabled = 0
        
        public static let DepthMinimum  = 2
        
        public static let DepthMaximum  = 10
        
        public static var DepthTitles : [String] {
            return DepthValues.map { DepthMap[$0]! }
        }
        
        public static var DepthValues : [Int] {
            return DepthMap.keys.sort()
        }
        
        public static var DepthMap : [Int : String] {
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
