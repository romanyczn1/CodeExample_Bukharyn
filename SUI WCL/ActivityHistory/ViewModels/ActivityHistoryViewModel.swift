//
//  ActivityHistoryViewModel.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import ActivityRepeat
import Analytics
import DataProvider
import Foundation
import UIComponents

// MARK: - ActivityHistoryViewModelState

enum ActivityHistoryViewModelState {
    case loading
    case success
    case failure(error: Error)
    case empty(isFiltersActive: Bool, isDateSelected: Bool)
}

// MARK: - ActivityHistoryViewModel

final class ActivityHistoryViewModel: ObservableObject, ActivityHistoryUpdater {
    private enum Constants {
        static let paginationStep = 10
    }

    // MARK: - Public Properties

    weak var moduleOutput: ActivityHistoryModuleOutput?

    @Published
    private(set) var state: ActivityHistoryViewModelState = .loading

    @Published
    private(set) var sections: [MonthSectionViewModel<ActivityCell>] = []

    @Published
    private(set) var pageLoaderState: PageLoaderState = .lastPage

    @Published
    var dateRange: ClosedRange<Date>?

    private var filters: ActivityHistoryFilters = .init()
    private var services: [DefaultFilterItem] = []
    private var trainers: [DefaultFilterItem] = []

    private(set) var isFiltersActive = false

    // MARK: - Private Properties

    private let worker: ActivityHistoryWorkerProtocol
    private let repeater: any ActivityRepeater<Activity>
    private let sectionGrouper: any SectionGrouper<ActivityCell>
    private let activityHistoryCellViewModelMapper: ActivityHistoryCellViewModelMapper

    // MARK: - Init

    init(worker: ActivityHistoryWorkerProtocol) {
        self.worker = worker
        repeater = ActivityRepeaterImpl()
        sectionGrouper = SectionGrouperImpl<ActivityCell>()
        activityHistoryCellViewModelMapper = ActivityHistoryCellViewModelMapperImpl()

        loadData(isFisrtLoading: true)
    }

    func loadData(isFisrtLoading: Bool = false) {
        state = .loading
        Task { @MainActor in
            if isFisrtLoading {
                _ = try? await worker.getObjectives()
            }
            do {
                let activitiesResponse = try await worker.getActivity(
                    limit: Constants.paginationStep,
                    startDate: startDate,
                    endDate: endDate,
                    filters: filters,
                    filterTrainers: trainers.filter(\.isSelected),
                    filterServices: services.filter(\.isSelected)
                )
                if activitiesResponse.activities.isEmpty {
                    state = .empty(isFiltersActive: isFiltersActive, isDateSelected: dateRange != nil)
                } else {
                    makeSections(activities: activitiesResponse.activities)
                    state = .success
                }
                pageLoaderState = activitiesResponse.isLastPage ? .lastPage : .waiting
            } catch {
                state = .failure(error: error)
            }
        }
    }

    func loadNextPage() {
        guard pageLoaderState.canLoadPage else { return }
        pageLoaderState = .loading

        Task { @MainActor in
            do {
                let activitiesResponse = try await worker.getActivity(
                    limit: Constants.paginationStep,
                    startDate: startDate,
                    endDate: endDate,
                    filters: filters,
                    filterTrainers: trainers.filter(\.isSelected),
                    filterServices: services.filter(\.isSelected)
                )
                makeSections(activities: activitiesResponse.activities)
                pageLoaderState = activitiesResponse.isLastPage ? .lastPage : .waiting
            } catch {
                self.pageLoaderState = .error
            }
        }
    }

    func reloadData() {
        sections.removeAll()
        worker.resetActivities()
        loadData()
    }

    func resetDate() {
        dateRange = nil
    }

    func filtersChanged(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        self.filters = filters
        self.services = services
        self.trainers = trainers

        isFiltersActive =
            !filters.isEmpty ||
            self.services.contains { $0.isSelected } ||
            self.trainers.contains { $0.isSelected }

        reloadData()
    }

    func openFilters() {
        moduleOutput?.userDidRequestToShowFilters(
            objectives: worker.objectives,
            currentFilters: filters,
            services: services,
            trainers: trainers
        )
    }

    private func makeSections(activities: [Activity]) {
        let items = activities
            .compactMap { [weak self] activity in
                self?.activityHistoryCellViewModelMapper.make(
                    activity: activity,
                    canRepeat: self?.repeater.repeat(from: activity) != nil,
                    onEvent: { [weak self] events in self?.handleEvents(event: events, activity: activity) }
                )
            }

        sections = sectionGrouper.groupByMonth(initialSections: sections, items: items)
    }

    private func handleEvents(
        event: ActivityCellEvents,
        activity: Activity
    ) {
        switch event {
        case .tapCell:
            moduleOutput?.userDidRequestToShowActivityCard(from: activity)
        case .repeat:
            handleRepeatActivity(activity: activity)
        }
    }

    private func handleRepeatActivity(activity: Activity) {
        guard let kind = repeater.repeat(from: activity) else { return }

        moduleOutput?.repeatActivity(kind: kind)
        trackRepeatWorkout(kind: kind, activity: activity)
    }
}

// MARK: - Computed Properties

extension ActivityHistoryViewModel {
    private var startDate: String? {
        if let dateRange {
            return DateFormatter.dateAndTimeISOWihtoutTimeZone.string(from: dateRange.lowerBound)
        }
        return nil
    }

    private var endDate: String? {
        if let dateRange {
            return DateFormatter.dateAndTimeISOWihtoutTimeZone.string(from: dateRange.upperBound)
        }
        return nil
    }

    var dateRangeString: String? {
        if let dateRange {
            let df = DateFormatter.fullDateShort
            return "\(df.string(from: dateRange.lowerBound)) - \(df.string(from: dateRange.upperBound))"
        }
        return nil
    }
}

// MARK: - Analytics

extension ActivityHistoryViewModel {
    func trackInit() {
        worker.analyticService?.track(event: AnalyticsConstants.SourceScreen.ActivityHistory.activityHistory)
    }

    private func trackActivityHistoryPay() {
        worker.analyticService?.track(event: AnalyticsConstants.MyActivity.activityHistoryPay)
    }

    private func trackRepeatWorkout(kind: ActivityRepeaterKind, activity: Activity) {
        guard case .clubActivity(let clubActivity) = activity.activity else { return }

        var event: String

        switch kind {
        case .personal:
            event = AnalyticsConstants.PersonalTrainings.tapToRepeatPersonalTraining
        case .group:
            event = AnalyticsConstants.GroupTrainings.tapToRepeatGroupTraining
        }

        worker.analyticService?.track(
            event: event,
            params: [
                AnalyticsConstants.Param.Services.serviceName: clubActivity.name
            ]
        )
    }
}
