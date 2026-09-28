import Foundation

public enum AddItemCategory: String, CaseIterable, Equatable, Sendable {
    case apps
    case links
    case widgets
}

public struct AddItemState: Equatable, Sendable {
    public let category: AddItemCategory
    public let searchQuery: String
    public let selectedIndex: Int?
    public let isVisible: Bool

    public init(
        category: AddItemCategory,
        searchQuery: String,
        selectedIndex: Int?,
        isVisible: Bool
    ) {
        self.category = category
        self.searchQuery = searchQuery
        self.selectedIndex = selectedIndex
        self.isVisible = isVisible
    }
}

public enum AddItemAction: Equatable, Sendable {
    case open
    case close
    case setCategory(AddItemCategory)
    case setSearchQuery(String, resultCount: Int)
    case selectNext(resultCount: Int)
    case selectPrevious(resultCount: Int)
}
