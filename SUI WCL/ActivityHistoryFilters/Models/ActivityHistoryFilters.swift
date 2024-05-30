//
//  ActivityHistoryFilters.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 14.01.24.
//
//

import Resources
import UIComponents

// MARK: - ActivityPriceFilter

enum ActivityPriceFilter: String, CaseIterable, SelectorCategory {
    case all
    case free
    case paid

    var title: String {
        switch self {
        case .all:
            return Strings.ActivityHistory.allFilter
        case .free:
            return Strings.ActivityHistory.priceFreeFilter
        case .paid:
            return Strings.ActivityHistory.pricePaidFilter
        }
    }

    var isExcluding: Bool {
        true
    }

    var isActive: Bool {
        true
    }
}

// MARK: - ActivityTypeFilter

enum ActivityTypeFilter: String, CaseIterable, SelectorCategory {
    case all
    case `self`
    case group
    case personal
    case visit

    var title: String {
        switch self {
        case .all:
            return Strings.ActivityHistory.allFilter
        case .self:
            return Strings.ActivityHistory.typeSelfFilter
        case .group:
            return Strings.ActivityHistory.typeGroupFilter
        case .personal:
            return Strings.ActivityHistory.typePersonalFilter
        case .visit:
            return Strings.ActivityHistory.typeVisitFilter
        }
    }

    var isExcluding: Bool {
        self == .all
    }

    var isActive: Bool {
        true
    }
}

// MARK: - ActivityObjectiveType

struct ActivityObjectiveType: SelectorCategory, ColoredCategory {
    public let id: String?
    public let title: String
    public let objectiveColor: String?
    public let isActive: Bool
    public let isExcluding: Bool

    public init(
        id: String?,
        title: String,
        isActive: Bool,
        objectiveColor: String?,
        isExcluding: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isActive = isActive
        self.objectiveColor = objectiveColor
        self.isExcluding = isExcluding
    }
}

// MARK: - ActivityHistoryFilters

struct ActivityHistoryFilters {
    let paymentTypeFilters: [ActivityPriceFilter]
    let activityTypeFilters: [ActivityTypeFilter]
    let objectiveTypeFilters: [ActivityObjectiveType]

    init() {
        paymentTypeFilters = []
        activityTypeFilters = []
        objectiveTypeFilters = []
    }

    init(
        paymentTypeFilters: [ActivityPriceFilter],
        activityTypeFilters: [ActivityTypeFilter],
        objectiveTypeFilters: [ActivityObjectiveType]
    ) {
        self.paymentTypeFilters = paymentTypeFilters
        self.activityTypeFilters = activityTypeFilters
        self.objectiveTypeFilters = objectiveTypeFilters
    }
}

// MARK: - ActivityHistoryFilters + Computed Properties

extension ActivityHistoryFilters {
    var isEmpty: Bool {
        let isPaymentTypeFiltersEmpty = paymentTypeFilters.isEmpty || paymentTypeFilters == [.all]
        let isActivityTypeFiltersEmpty = activityTypeFilters.isEmpty || activityTypeFilters == [.all]
        let isObjectiveTypeFiltersEmpty =
            objectiveTypeFilters.isEmpty ||
            objectiveTypeFilters.first?.id == nil
        return isPaymentTypeFiltersEmpty && isActivityTypeFiltersEmpty && isObjectiveTypeFiltersEmpty
    }

    var paymentType: String? {
        if let paymentType = paymentTypeFilters.first, paymentType != .all {
            return paymentType.rawValue
        }
        return nil
    }

    var activityTypes: [String]? {
        if activityTypeFilters.isEmpty || activityTypeFilters == [.all] {
            return nil
        } else {
            return activityTypeFilters.map(\.rawValue)
        }
    }

    var objectiveTypes: [String]? {
        if objectiveTypeFilters.isEmpty {
            return nil
        } else {
            if objectiveTypeFilters.first?.id == nil {
                return nil
            } else {
                return objectiveTypeFilters.compactMap(\.id)
            }
        }
    }
}
