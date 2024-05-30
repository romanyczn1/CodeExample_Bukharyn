//
//  ActivityHistoryService.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 15.01.24.
//
//

import DataProvider
import Foundation

// MARK: - ActivityHistoryServiceProtocol

protocol ActivityHistoryServiceProtocol {
    func getActivity(
        limit: Int,
        offset: Int?,
        startDate: String?,
        endDate: String?,
        filterTypes: [String]?,
        filterObjectives: [String]?,
        filterPayment: String?,
        filterTrainers: [String]?,
        filterServices: [String]?
    ) async throws -> Activities
    func getObjectives() async throws -> [DataProvider.Objective]
}

// MARK: - ActivityHistoryService

final class ActivityHistoryService {
    private let activityService: ActivityService
    private let objectivesService: ObjectivesService

    init(
        activityService: ActivityService,
        objectivesService: ObjectivesService
    ) {
        self.activityService = activityService
        self.objectivesService = objectivesService
    }
}

// MARK: ActivityHistoryServiceProtocol

extension ActivityHistoryService: ActivityHistoryServiceProtocol {
    func getActivity(
        limit: Int,
        offset: Int?,
        startDate: String?,
        endDate: String?,
        filterTypes: [String]?,
        filterObjectives: [String]?,
        filterPayment: String?,
        filterTrainers: [String]?,
        filterServices: [String]?
    ) async throws -> Activities {
        return try await activityService.getActivity(
            limit: limit,
            offset: offset,
            startDate: startDate,
            endDate: endDate,
            filterTypes: filterTypes,
            filterObjectives: filterObjectives,
            filterPayment: filterPayment,
            filterTrainers: filterTrainers,
            filterServices: filterServices
        )
    }

    func getObjectives() async throws -> [DataProvider.Objective] {
        try await objectivesService.getObjectives()
    }
}
