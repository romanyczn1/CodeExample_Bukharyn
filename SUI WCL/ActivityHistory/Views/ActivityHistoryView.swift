//
//  ActivityHistoryView.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import Resources
import SwiftUI
import UIComponents

// MARK: - ActivityHistoryView

struct ActivityHistoryView: View {
    // MARK: - Private Properties

    private enum Constants {
        static let calendarButtonBottomPadding: CGFloat = 8
    }

    @State
    private var showDatePicker: Bool = false

    @ObservedObject
    private var viewModel: ActivityHistoryViewModel

    @State
    private var calendarButtonHeight: CGFloat = 0

    // MARK: - Init

    init(viewModel: ActivityHistoryViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Layout

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .success:
                makeHistoryView()
            case .failure(let error):
                ErrorEmptyView(error: error) {
                    viewModel.reloadData()
                }
            case .empty(let isFiltersActive, let isDateSelected):
                makeEmptyView(isFiltersActive: isFiltersActive, isDateSelected: isDateSelected)
            }
        }
        .onAppear {
            viewModel.trackInit()
        }
    }

    private func makeHistoryView() -> some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.items) { dateSection in
                                VStack(alignment: .leading, spacing: 0, content: {
                                    DateSectionHeader(
                                        viewModel: dateSection.header,
                                        topPadding: 24
                                    )
                                    .id(UUID().uuidString)

                                    ForEach(dateSection.items) { item in
                                        switch item {
                                        case .club(let viewModel):
                                            ClubActivityCellView(viewModel: viewModel)
                                        case .custom(let viewModel):
                                            CustomActivityCellView(viewModel: viewModel)
                                        }
                                    }
                                })
                            }
                        } header: {
                            MonthSectionHeader(
                                viewModel: section.header
                            )
                            .id(UUID().uuidString)
                        }
                    }

                    PageLoadingView(
                        state: viewModel.pageLoaderState,
                        action: viewModel.loadNextPage,
                        topPadding: 0,
                        bottomPadding: 8,
                        errorTitle: Strings.ActivityHistory.activityHistoryPageLoadingErrorTitle,
                        errorSubtitle: Strings.ActivityHistory.activityHistoryPageLoadingErrorSubtitle
                    )

                    Spacer()
                        .frame(height: 60)
                }
            }

            calendarButton
        }
        .overlay(datePickerView)
    }

    private func makeEmptyView(isFiltersActive: Bool, isDateSelected: Bool) -> some View {
        EmptyListView(viewModel: .init(
            image: Images.emptyListSmall.image,
            title: isFiltersActive || isDateSelected ?
                Strings.ActivityHistory.noActivities :
                Strings.ActivityHistory.noActivitiesAtAll,
            description: isFiltersActive ?
                Strings.ActivityHistory.noActivitiesWithFilter :
                nil,
            buttonTitle: isFiltersActive ?
                Strings.ActivityHistory.changeFilter :
                nil,
            buttonAction: viewModel.openFilters
        ))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            calendarView(isFiltersActive: isFiltersActive, isDateSelected: isDateSelected),
            alignment: Alignment(horizontal: .center, vertical: .bottom)
        )
        .overlay(datePickerView)
    }

    private func calendarView(isFiltersActive: Bool, isDateSelected: Bool) -> some View {
        Group {
            if isFiltersActive || isDateSelected {
                calendarButton
            } else {
                EmptyView()
            }
        }
    }

    private var calendarButton: some View {
        Group {
            if let dateRangeString = viewModel.dateRangeString {
                HStack(alignment: .center, spacing: 4) {
                    Text(dateRangeString)
                        .disabledScalingTextStyle(.bodyText, color: ColorsUI.white)

                    ImagesUI.cross
                        .renderingMode(.template)
                        .foregroundColor(ColorsUI.white)
                        .asButton {
                            viewModel.resetDate()
                            viewModel.reloadData()
                        }
                }
            } else {
                ImagesUI.mapCalendar
                    .renderingMode(.template)
                    .foregroundColor(ColorsUI.lightGrey)
            }
        }
        .padding(.init(vertical: 10, horizontal: 24))
        .background(
            GeometryReader(content: { geo in
                DispatchQueue.main.async {
                    calendarButtonHeight = geo.size.height
                }
                return RoundedRectangle(cornerRadius: geo.size.height / 2)
                    .fill(ColorsUI.black)

            })
        )
        .asButton {
            showDatePicker = true
        }
        .padding(.vertical, Constants.calendarButtonBottomPadding)
    }

    private var datePickerView: some View {
        ZStack(alignment: .bottom) {
            if showDatePicker {
                Color.black.opacity(0.01)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showDatePicker.toggle()
                            viewModel.reloadData()
                        }
                    }

                MultiDatePicker(dateRange: $viewModel.dateRange, maxDate: Date())
                    .padding(.bottom, 2 * Constants.calendarButtonBottomPadding + calendarButtonHeight)
            } else {
                EmptyView()
            }
        }
    }
}
