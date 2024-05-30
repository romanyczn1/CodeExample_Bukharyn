//
//  ActivityHistoryDataStore.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 15.01.24.
//
//

import DataProvider
import Foundation

// MARK: - ActivityHistoryDataStoreProtocol

protocol ActivityHistoryDataStoreProtocol {
    var objectives: [Objective] { get set }
    var activities: [Activity] { get set }
}

// MARK: - ActivityHistoryDataStore

final class ActivityHistoryDataStore: ActivityHistoryDataStoreProtocol {
    var objectives: [DataProvider.Objective] = []
    var activities: [Activity] = []
}
