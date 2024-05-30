//
//  ActivityHistoryFiltersView.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 12.01.24.
//
//

import DataProvider
import Resources
import SwiftUI
import UIComponents

// MARK: - ActivityHistoryFiltersView

struct ActivityHistoryFiltersView: View {
    // MARK: - Private Properties

    @ObservedObject private var viewModel: ActivityHistoryFiltersViewModel

    // MARK: - Init

    init(viewModel: ActivityHistoryFiltersViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Layout

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let objectiveSelectorViewModel = viewModel.objectiveSelectorViewModel {
                        CategorySelectorView<ActivityObjectiveType>(viewModel: objectiveSelectorViewModel)
                            .padding(trailing: -10, bottom: 24)
                    }

                    CategorySelectorView<ActivityTypeFilter>(viewModel: viewModel.typeSelectorViewModel)
                        .padding(trailing: -10, bottom: 24)

                    ColorsUI.black20
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)

                    Text(Strings.ActivityHistory.filterRestrictions)
                        .textStyle(.additionalInfo, color: ColorsUI.black50)

                    CategorySelectorView<ActivityPriceFilter>(viewModel: viewModel.priceSelectorViewModel)
                        .padding(trailing: -10, bottom: 24)

                    DisclosureCellView(
                        title: Strings.ActivityHistory.filterActivitiesSectionTitle,
                        indicatorCount: viewModel.selectedServicesCount,
                        action: viewModel.showActivities
                    )

                    DisclosureCellView(
                        title: Strings.ActivityHistory.filterTrainersSectionTitle,
                        indicatorCount: viewModel.selectedTrainersCount,
                        action: viewModel.showTrainers
                    )
                    .padding(.bottom, 92)
                }
            }
            .padding(horizontal: 24)

            GradientButtonView(
                buttonText: Strings.ActivityHistory.applyFiltersButton,
                buttonAction: viewModel.applyFilters
            )
        }
    }
}
