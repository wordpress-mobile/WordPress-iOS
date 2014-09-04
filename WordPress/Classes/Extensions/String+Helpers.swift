import Foundation

extension String
{
    public subscript (i: Int) -> String {
        return String(Array(self)[i])
    }
}
