//
//  ActivityHistoryWorker.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 15.01.24.
//
//

import Analytics
import DataProvider
import Foundation

// MARK: - ActivityHistoryWorkerProtocol

protocol ActivityHistoryWorkerProtocol {
    var analyticService: Analytics? { get }
    var objectives: [Objective] { get }
    func getActivity(
        limit: Int,
        startDate: String?,
        endDate: String?,
        filters: ActivityHistoryFilters,
        filterTrainers: [DefaultFilterItem],
        filterServices: [DefaultFilterItem]
    ) async throws -> Activities
    func resetActivities()
    func getObjectives() async throws -> [Objective]
}

// MARK: - ActivityHistoryWorker

final class ActivityHistoryWorker: ActivityHistoryWorkerProtocol {
    // MARK: - Public Properties

    var objectives: [Objective] {
        dataStore.objectives
    }

    var analyticService: Analytics?

    // MARK: - Private Properties
    private var dataStore: ActivityHistoryDataStoreProtocol
    private let service: ActivityHistoryServiceProtocol
    private let defaultActivities: [Activity]?

    // MARK: - Init
    init(
        analytics: Analytics?,
        dataStore: ActivityHistoryDataStoreProtocol,
        service: ActivityHistoryServiceProtocol,
        defaultActivities: [Activity]?
    ) {
        analyticService = analytics
        self.dataStore = dataStore
        self.defaultActivities = defaultActivities
        self.service = service
    }

    func getActivity(
        limit: Int,
        startDate: String?,
        endDate: String?,
        filters: ActivityHistoryFilters,
        filterTrainers: [DefaultFilterItem],
        filterServices: [DefaultFilterItem]
    ) async throws -> Activities {
        if dataStore.activities.isEmpty {
            // track only first request
            trackDidLoadHistory()
        }
        let response = try await service.getActivity(
            limit: limit,
            offset: dataStore.activities.count,
            startDate: startDate,
            endDate: endDate,
            filterTypes: filters.activityTypes,
            filterObjectives: filters.objectiveTypes,
            filterPayment: filters.paymentType,
            filterTrainers: filterTrainers.isEmpty ? nil : filterTrainers.map(\.uid),
            filterServices: filterServices.isEmpty ? nil : filterServices.map(\.uid)
        )
        if dataStore.activities.isEmpty {
            dataStore.activities = response.activities
        } else {
            dataStore.activities.append(contentsOf: response.activities)
        }
        return response
    }

    func resetActivities() {
        dataStore.activities = []
    }

    func getObjectives() async throws -> [Objective] {
        let objectives = try await service.getObjectives()
        dataStore.objectives = objectives
        return objectives
    }
}

// MARK: AnalyticsTrackable

extension ActivityHistoryWorker: AnalyticsTrackable {
    private func trackDidLoadHistory() {
        analyticService?.track(event: AnalyticsConstants.MyActivity.activityHistoryLoad)
    }
}
