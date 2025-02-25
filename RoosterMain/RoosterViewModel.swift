//
//  RoosterViewModel.swift
//  Tasker
//
//  Created by Siddharth Sehgal on 16/02/2025.
//

import Foundation
import SwiftUI

@MainActor
class RoosterViewModel: ObservableObject {
    @Published var entries: [RoosterEntry] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let zermeloManager = ZermeloManager.shared
    private let firebaseManager = FirebaseManager.shared
    private let authManager = AuthManager.shared
    
    // For caching
    private var lastLoadedWeek: Date?
    private var lastLoadedEntries: [RoosterEntry] = []
    
    func loadSchedule(for week: Date) async {
        if let lastWeek = lastLoadedWeek,
           Calendar.current.isDate(lastWeek, equalTo: week, toGranularity: .weekOfYear) {
            entries = lastLoadedEntries
            return
        }
        
        isLoading = true
        
        do {
            let calendar = Calendar.current
            let startOfWeek = calendar.startOfDay(for: calendar.startOfWeek(for: week))
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            let start = Int(startOfWeek.timeIntervalSince1970)
            let end = Int(endOfWeek.timeIntervalSince1970)
            
            let appointments = try await zermeloManager.fetchSchedule(start: start, end: end)
            
            let zermeloEntries = appointments.map { appointment in
                RoosterEntry(
                    id: String(appointment.id),
                    title: appointment.subjects.first ?? "Onbekend",
                    startTime: Date(timeIntervalSince1970: TimeInterval(appointment.start)),
                    endTime: Date(timeIntervalSince1970: TimeInterval(appointment.end)),
                    color: getColorForSubject(appointment.subjects.first ?? ""),
                    teacher: appointment.teachers.first,
                    room: appointment.locations.first,
                    description: appointment.changeDescription.isEmpty ? nil : appointment.changeDescription,
                    isRecurring: false
                )
            }
            
            let userId = authManager.currentUserId ?? ""
            let manualEntries = await firebaseManager.fetchRoosterEntries(userId: userId)
            
            let allEntries = (zermeloEntries + manualEntries).sorted { $0.startTime < $1.startTime }
            
            lastLoadedWeek = week
            lastLoadedEntries = allEntries
            entries = allEntries
            
        } catch {
            self.error = error
            print("Error loading schedule: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func addEntry(_ entry: RoosterEntry) {
        entries.append(entry)
        entries.sort { $0.startTime < $1.startTime }
        
        if let userId = authManager.currentUserId {
            firebaseManager.saveRoosterEntry(entry, userId: userId)
        }
    }
    
    func updateEntry(_ entry: RoosterEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            entries.sort { $0.startTime < $1.startTime }
            
            if let userId = authManager.currentUserId {
                firebaseManager.saveRoosterEntry(entry, userId: userId)
            }
        }
    }
    
    func deleteEntry(_ entry: RoosterEntry) {
        entries.removeAll { $0.id == entry.id }
        
        if let userId = authManager.currentUserId {
            firebaseManager.deleteRoosterEntry(userId: userId, entryId: entry.id)
        }
        
        if let calendarEventId = entry.calendarEventId {
            GoogleCalendarManager.shared.deleteCalendarEvent(eventId: calendarEventId) { _ in }
        }
    }
    
    private func getColorForSubject(_ subject: String) -> String {
        let colors = [
            "#FF9500", // Orange
            "#FF2D55", // Red
            "#5856D6", // Purple
            "#34C759", // Green
            "#007AFF", // Blue
            "#FF9EAC", // Pink
            "#BF5AF2", // Purple
            "#FFD60A"  // Yellow
        ]
        
        let index = abs(subject.hashValue) % colors.count
        return colors[index]
    }
}
