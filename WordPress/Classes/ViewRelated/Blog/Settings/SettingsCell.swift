import SwiftUI

 struct SettingsCell: View {
     let title: String
     let value: String?
     var placeholder: String?

     var body: some View {
         HStack {
             Text(title)
                 .layoutPriority(1)
                 .foregroundColor(.primary)
             Spacer()
             Text(value ?? (placeholder ?? ""))
                 .foregroundColor(.secondary)
         }
         .lineLimit(1)
     }
 }
