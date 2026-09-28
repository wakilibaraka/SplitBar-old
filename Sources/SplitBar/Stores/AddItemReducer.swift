import Foundation

public func filterApplications(
    applications: [ApplicationDescriptor],
    query: String
) -> [ApplicationDescriptor] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let filtered: [ApplicationDescriptor]
    if trimmed.isEmpty {
        filtered = applications
    } else {
        filtered = applications.filter {
            $0.displayName.localizedCaseInsensitiveContains(trimmed)
        }
    }
    return filtered.sorted {
        $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
    }
}

public func reduceAddItem(
    state: AddItemState,
    action: AddItemAction
) -> AddItemState {
    switch action {
    case .open:
        return AddItemState(
            category: state.category,
            searchQuery: "",
            selectedIndex: 0,
            isVisible: true
        )
    case .close:
        return AddItemState(
            category: state.category,
            searchQuery: "",
            selectedIndex: nil,
            isVisible: false
        )
    case .setCategory(let category):
        return AddItemState(
            category: category,
            searchQuery: "",
            selectedIndex: 0,
            isVisible: state.isVisible
        )
    case .setSearchQuery(let query, let resultCount):
        let newIndex: Int?
        if resultCount == 0 {
            newIndex = nil
        } else if let current = state.selectedIndex {
            newIndex = min(current, resultCount - 1)
        } else {
            newIndex = 0
        }
        return AddItemState(
            category: state.category,
            searchQuery: query,
            selectedIndex: newIndex,
            isVisible: state.isVisible
        )
    case .selectNext(let resultCount):
        guard resultCount > 0 else {
            return AddItemState(
                category: state.category,
                searchQuery: state.searchQuery,
                selectedIndex: nil,
                isVisible: state.isVisible
            )
        }
        let current = state.selectedIndex ?? 0
        let newIndex = min(current + 1, resultCount - 1)
        return AddItemState(
            category: state.category,
            searchQuery: state.searchQuery,
            selectedIndex: newIndex,
            isVisible: state.isVisible
        )
    case .selectPrevious(let resultCount):
        guard resultCount > 0 else {
            return AddItemState(
                category: state.category,
                searchQuery: state.searchQuery,
                selectedIndex: nil,
                isVisible: state.isVisible
            )
        }
        let current = state.selectedIndex ?? 0
        let newIndex = max(current - 1, 0)
        return AddItemState(
            category: state.category,
            searchQuery: state.searchQuery,
            selectedIndex: newIndex,
            isVisible: state.isVisible
        )
    }
}
