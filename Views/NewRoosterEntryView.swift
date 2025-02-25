//
//  NewRoosterEntryView.swift
//  Tasker
//
//  Created by Siddharth Sehgal on 20/01/2025.
//

import SwiftUI

struct NewRoosterEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var roosterEntries: [RoosterEntry]
    let userId: String
    let selectedDate: Date
    
    @State private var title = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedColor = "#FF9500"
    @State private var teacher = ""
    @State private var room = ""
    @State private var description = ""
    @State private var isRecurring = false
    @State private var showingGoogleCalendarSync = false
    @State private var showingTitleLimitError = false
    
    let colors = ["#FF9500", "#FF2D55", "#5856D6", "#34C759", "#007AFF"]
    
    init(roosterEntries: Binding<[RoosterEntry]>, userId: String, selectedDate: Date) {
        self._roosterEntries = roosterEntries
        self.userId = userId
        self.selectedDate = selectedDate
        
        // Initialize times to the selected date
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = 9  // Default start time 9:00
        components.minute = 0
        let initialStartTime = calendar.date(from: components) ?? Date()
        _startTime = State(initialValue: initialStartTime)
        _endTime = State(initialValue: initialStartTime.addingTimeInterval(3600)) // 1 hour duration
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Vaknaam", systemImage: "book.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Voer vaknaam in", text: Binding(
                            get: { title },
                            set: { newValue in
                                if newValue.count <= CharacterLimits.lessonTitle {
                                    title = newValue
                                } else {
                                    showingTitleLimitError = true
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !title.isEmpty {
                            Text("\(title.count)/\(CharacterLimits.lessonTitle)")
                                .font(.caption)
                                .foregroundColor(title.count >= CharacterLimits.lessonTitle ? .red : .secondary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Time Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tijden", systemImage: "clock.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("Start", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("Eind", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Teacher & Room Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Details", systemImage: "person.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Docent (optioneel)", text: $teacher)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Lokaal (optioneel)", text: $room)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Kleur", systemImage: "paintpalette.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color) ?? .orange)
                                    .frame(width: 35, height: 35)
                                    .overlay(
                                        Circle()
                                            .stroke(color == selectedColor ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Recurring Option
                    Toggle(isOn: $isRecurring) {
                        Label("Wekelijks Herhalen", systemImage: "repeat")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Google Calendar Sync
                    Toggle(isOn: $showingGoogleCalendarSync) {
                        Label("Synchroniseer met Google Agenda", systemImage: "calendar")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Nieuwe Les")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Toevoegen") {
                        addEntry()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("Karakterlimiet Overschreden", isPresented: $showingTitleLimitError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vaknaam is beperkt tot \(CharacterLimits.lessonTitle) karakters.")
            }
        }
    }
    
    private func addEntry() {
        let newEntry = RoosterEntry(
            title: title,
            startTime: startTime,
            endTime: endTime,
            color: selectedColor,
            teacher: teacher.isEmpty ? nil : teacher,
            room: room.isEmpty ? nil : room,
            description: description.isEmpty ? nil : description,
            isRecurring: isRecurring
        )
        
        if showingGoogleCalendarSync {
            syncWithGoogleCalendar(newEntry)
        } else {
            saveEntry(newEntry)
        }
    }
    
    // In the createGoogleCalendarEvent function, instead of modifying the entry
    // Add this function to the NewRoosterEntryView struct
    private func syncWithGoogleCalendar(_ entry: RoosterEntry) {
        let recurrenceRule = entry.isRecurring ? "RRULE:FREQ=WEEKLY" : nil
        
        GoogleCalendarManager.shared.syncTimeTableEntryToCalendar(
            entry: entry,
            recurrenceRule: recurrenceRule
        ) { success, eventId in
            if success {
                // Create a new entry with the calendar event ID
                let updatedEntry = RoosterEntry(
                    id: entry.id,
                    title: entry.title,
                    startTime: entry.startTime,
                    endTime: entry.endTime,
                    color: entry.color,
                    teacher: entry.teacher,
                    room: entry.room,
                    description: entry.description,
                    calendarEventId: eventId,
                    isRecurring: entry.isRecurring,
                    recurrenceRule: recurrenceRule
                )
                saveEntry(updatedEntry)
            } else {
                saveEntry(entry)
            }
        }
    }

    // And update the saveEntry function to handle Google Calendar sync
    private func saveEntry() {
        let entry = RoosterEntry(
            title: title,
            startTime: startTime,
            endTime: endTime,
            color: selectedColor,
            teacher: teacher.isEmpty ? nil : teacher,
            room: room.isEmpty ? nil : room,
            description: description.isEmpty ? nil : description,
            isRecurring: isRecurring
        )
        
        if showingGoogleCalendarSync {
            syncWithGoogleCalendar(entry)
        } else {
            saveEntry(entry)
        }
    }

    private func saveEntry(_ entry: RoosterEntry) {
        roosterEntries.append(entry)
        FirebaseManager.shared.saveRoosterEntry(entry, userId: userId)
        dismiss()
    }
}

#Preview {
    NewRoosterEntryView(
        roosterEntries: .constant([]),
        userId: "preview",
        selectedDate: Date()
    )
}
