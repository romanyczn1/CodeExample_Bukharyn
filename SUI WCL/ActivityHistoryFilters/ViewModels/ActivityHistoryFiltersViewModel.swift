//
//  ActivityHistoryFiltersViewModel.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 12.01.24.
//
//

import Combine
import DataProvider
import Foundation
import UIComponents

// MARK: - ActivityHistoryFiltersViewModel

class ActivityHistoryFiltersViewModel: ObservableObject {
    // MARK: - Public Properties

    @Published
    var services: [DefaultFilterItem]

    @Published
    var trainers: [DefaultFilterItem]

    @Published
    var isResetButtonVisible = false

    var selectedServicesCount: Int {
        services.filter(\.isSelected).count
    }

    var selectedTrainersCount: Int {
        trainers.filter(\.isSelected).count
    }

    var hasSelectedItems: Bool {
        services.contains { $0.isSelected } || trainers.contains { $0.isSelected }
    }

    var objectiveSelectorViewModel: CategorySelectorViewModel<ActivityObjectiveType>?
    var typeSelectorViewModel: CategorySelectorViewModel<ActivityTypeFilter>
    var priceSelectorViewModel: CategorySelectorViewModel<ActivityPriceFilter>

    weak var moduleOutput: ActivityHistoryFiltersModuleOutput?

    // MARK: - Private Properties

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Init

    init(
        objectiveSelectorViewModel: CategorySelectorViewModel<ActivityObjectiveType>?,
        typeSelectorViewModel: CategorySelectorViewModel<ActivityTypeFilter>,
        priceSelectorViewModel: CategorySelectorViewModel<ActivityPriceFilter>,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        self.objectiveSelectorViewModel = objectiveSelectorViewModel
        self.typeSelectorViewModel = typeSelectorViewModel
        self.priceSelectorViewModel = priceSelectorViewModel
        self.services = services
        self.trainers = trainers

        objectiveSelectorViewModel?.$selectedCategories.sink { [weak self] objectives in
            self?.updateIsResetButtonVisible(objectivesChanged: objectives)
        }.store(in: &subscriptions)

        typeSelectorViewModel.$selectedCategories.sink { [weak self] type in
            self?.updateIsResetButtonVisible(typeChanged: type)
        }.store(in: &subscriptions)

        priceSelectorViewModel.$selectedCategories.sink { [weak self] price in
            self?.updateIsResetButtonVisible(priceChanged: price)
        }.store(in: &subscriptions)
    }

    func showActivities() {
        moduleOutput?.activityHistoryFiltersModuleDidRequestToShowActivitiesList(currentServices: services)
    }

    func showTrainers() {
        moduleOutput?.activityHistoryFiltersModuleDidRequestToShowTrainersList(currentTrainers: trainers)
    }

    func applyFilters() {
        let filters = ActivityHistoryFilters(
            paymentTypeFilters: priceSelectorViewModel.selectedCategories,
            activityTypeFilters: typeSelectorViewModel.selectedCategories,
            objectiveTypeFilters: objectiveSelectorViewModel?.selectedCategories ?? []
        )

        moduleOutput?.activityHistoryFiltersModuleDidApplyFilters(
            filters: filters,
            services: services,
            trainers: trainers
        )
    }

    func resetFilters() {
        for i in 0 ..< services.count {
            services[i].isSelected = false
        }
        for i in 0 ..< trainers.count {
            trainers[i].isSelected = false
        }
        if let allObjectivesCategory = objectiveSelectorViewModel?.categories.first(where: { $0.id == nil }) {
            objectiveSelectorViewModel?.selectedCategories = [allObjectivesCategory]
        }
        priceSelectorViewModel.selectedCategories = [.all]
        typeSelectorViewModel.selectedCategories = [.all]
    }

    // MARK: - Private Methods

    private func updateIsResetButtonVisible(
        objectivesChanged newObjectives: [ActivityObjectiveType]? = nil,
        typeChanged newType: [ActivityTypeFilter]? = nil,
        priceChanged newPrice: [ActivityPriceFilter]? = nil
    ) {
        let currentObjectives = objectiveSelectorViewModel?.selectedCategories
        let firstObjective = (newObjectives?.first ?? currentObjectives?.first)
        let isDefaultObjectiveCategories = firstObjective?.id == nil

        let isDefaultTypeCategories = (newType ?? typeSelectorViewModel.selectedCategories) == [.all]

        let isDefaultPriceCategories = (newPrice ?? priceSelectorViewModel.selectedCategories) == [.all]

        isResetButtonVisible = !isDefaultObjectiveCategories ||
            !isDefaultPriceCategories ||
            !isDefaultTypeCategories ||
            hasSelectedItems
    }
}

// MARK: ActivityHistoryFiltersUpdater

extension ActivityHistoryFiltersViewModel: ActivityHistoryFiltersUpdater {
    func update(services: [DefaultFilterItem]) {
        self.services = services
        updateIsResetButtonVisible()
    }

    func update(trainers: [DefaultFilterItem]) {
        self.trainers = trainers
        updateIsResetButtonVisible()
    }
}
