//
//  RoosterItemView.swift
//  Tasker
//
//  Created by Siddharth Sehgal on 20/01/2025.
//

import SwiftUI

struct RoosterItemView: View {
    let entry: RoosterEntry
    @Binding var roosterEntries: [RoosterEntry]
    let userId: String
    
    @State private var showingOptionsSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Time
                VStack(alignment: .leading) {
                    Text(formatTime(entry.startTime))
                        .font(.headline)
                    Text(formatTime(entry.endTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 65)
                
                Rectangle()
                    .fill(Color(hex: entry.color) ?? .orange)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                // Subject Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                    
                    if let teacher = entry.teacher {
                        Text(teacher)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let room = entry.room {
                        Text("Lokaal: \(room)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Options Button
                Button(action: { showingOptionsSheet = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
        .confirmationDialog("Lesopties", isPresented: $showingOptionsSheet) {
            Button("Bewerken") { showingEditSheet = true }
            Button("Verwijderen", role: .destructive) { showingDeleteAlert = true }
            Button("Annuleren", role: .cancel) { }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRoosterEntryView(
                entry: entry,
                roosterEntries: $roosterEntries,
                userId: userId
            )
        }
        .alert("Les Verwijderen", isPresented: $showingDeleteAlert) {
            Button("Verwijderen", role: .destructive) { deleteEntry() }
            Button("Annuleren", role: .cancel) { }
        } message: {
            Text("Weet je zeker dat je deze les wilt verwijderen?")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func deleteEntry() {
        if let calendarEventId = entry.calendarEventId {
            GoogleCalendarManager.shared.deleteCalendarEvent(eventId: calendarEventId) { _ in }
        }
        FirebaseManager.shared.deleteRoosterEntry(userId: userId, entryId: entry.id)
        roosterEntries.removeAll { $0.id == entry.id }
    }
}
