//
//  WeekScheduleView.swift
//  Tasker
//
//  Created by Siddharth Sehgal on 16/02/2025.
//

import SwiftUI

struct WeekScheduleView: View {
    @StateObject private var viewModel = RoosterViewModel()
    @State private var selectedDate = Date()
    @State private var viewMode: ViewMode = .week
    
    enum ViewMode {
        case day
        case week
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View mode selector
                Picker("Weergave", selection: $viewMode) {
                    Text("Dag").tag(ViewMode.day)
                    Text("Week").tag(ViewMode.week)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Date navigation
                HStack {
                    Button(action: previousPeriod) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text(periodLabel)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: nextPeriod) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if viewMode == .week {
                            // Week view - group by days
                            ForEach(daysInCurrentWeek, id: \.self) { day in
                                let dayEntries = entriesForDay(day)
                                if !dayEntries.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formatDayHeader(day))
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(dayEntries) { entry in
                                            RoosterItemView(
                                                entry: entry,
                                                roosterEntries: .constant(viewModel.entries),
                                                userId: AuthManager.shared.currentUserId ?? ""
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                    Divider()
                                }
                            }
                        } else {
                            // Day view
                            let dayEntries = entriesForDay(selectedDate)
                            ForEach(dayEntries) { entry in
                                RoosterItemView(
                                    entry: entry,
                                    roosterEntries: .constant(viewModel.entries),
                                    userId: AuthManager.shared.currentUserId ?? ""
                                )
                                .padding(.horizontal)
                            }
                            
                            if dayEntries.isEmpty {
                                Text("Geen lessen voor deze dag")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: logout) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await loadSchedule()
        }
    }
    
    private var periodLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE d MMMM yyyy"
        case .week:
            formatter.dateFormat = "d MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }
    
    private var daysInCurrentWeek: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0...6).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }
    
    private func formatDayHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }
    
    private func entriesForDay(_ date: Date) -> [RoosterEntry] {
        let calendar = Calendar.current
        return viewModel.entries.filter { entry in
            calendar.isDate(entry.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
    }
    
    private func previousPeriod() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        }
        Task {
            await loadSchedule()
        }
    }
    
    private func nextPeriod() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        }
        Task {
            await loadSchedule()
        }
    }
    
    private func refresh() {
        Task {
            await loadSchedule()
        }
    }
    
    private func loadSchedule() async {
        await viewModel.loadSchedule(for: selectedDate)
    }
    
    private func logout() {
        ZermeloAuthManager.shared.logout()
    }
}
