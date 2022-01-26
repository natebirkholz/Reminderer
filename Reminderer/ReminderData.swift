// ReminderData.swift
// Created by Nate Birkholz

import Foundation

struct ReminderData: Codable {
    let id: String
    let timer: TimeInterval
    let snooze: TimeInterval
    
    var endTime: TimeInterval?
    var reminderState: ReminderState
    var runtime: TimeInterval? {
        switch reminderState {
        case .none:
            return nil
        case .running:
            return timer
        case .snoozed:
            return snooze
        case .alerting:
            return nil
        }
    }
    
    init(timer: TimeInterval, snooze: TimeInterval) {
        self.id = UUID().uuidString
        self.timer = timer
        self.snooze = snooze
        
        self.reminderState = .none
    }
}

