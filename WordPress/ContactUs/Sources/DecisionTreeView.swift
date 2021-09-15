import SwiftUI

// When looking at the SwiftUI examples from Apple, they don't normally use the "View" suffix
// in the `View`-conforming type names. The rationale, I think, is that the fact that the type is
// a `View` is part of its type signature, therefore adding it to the name is redundant. Omitting it
// also keeps the code leaner. In this case, I added it to distinguish it from the already defined
// `DecisionTree` type (`typealias`, really).
public struct DecisionTreeView: View {

    private let tree: DecisionTree

    @State private var webViewSheetPresented = false

    public init(tree: DecisionTree) {
        self.tree = tree
    }

    public var body: some View {
        List(tree) { item in
            switch item.next {
            case .page(let nextSubTree):
                NavigationLink(destination: DecisionTreeView(tree: nextSubTree)) {
                    Text(item.message)
                }
            case .url(let url):
                NavigationLink(destination: WebView(url: url)) {
                    Text(item.message)
                }
            }
        }
    }
}
