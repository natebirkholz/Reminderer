// Reminder.swift
// Created by Nate Birkholz

import Foundation
import AVFoundation
import UserNotifications

struct TimeConstants {
    static var baseline: Double =  20
    static var lowVariance: Double = 5
    static var highVariance: Double = 25
    
    static var snoozeBaseline: Double = 5
    static var snoozeLowVariance: Double = 0.5
    static var snoozeHighVariance: Double = 5
}

enum TimerState {
    case none, running, snoozed, alerting
}

class Reminder {
    private var reminder: Timer?
    private(set) var state: TimerState = .none
    let id = UUID().uuidString
    
    func start() {
        let interval = randomize(forSnooze: false)
        fire(after: interval)
        state = .running
    }
    
    func snooze(completionHandler: (() -> ())) {
        let interval = randomize(forSnooze: true)
        fire(after: interval)
        state = .snoozed
    }
    
    @objc func fire(after timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "It's that time!"
        content.body = "Time to tap a button."
        let name = UNNotificationSoundName("Kazoos.wav")
        let sound = UNNotificationSound(named: name)
        content.sound = sound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] maybeError in
            self?.state = .alerting
        }
    }
    
    
    
    func cancel() {
        reminder?.invalidate()
        state = .none
    }
    
    private func randomize(forSnooze: Bool) -> TimeInterval {
        let length: TimeInterval
        if forSnooze {
            let random = Double.random(in: TimeConstants.snoozeLowVariance...TimeConstants.snoozeHighVariance)
            let total = random + TimeConstants.snoozeBaseline
            length = TimeInterval(minutes: total)
        } else {
            let random = Double.random(in: TimeConstants.lowVariance...TimeConstants.highVariance)
            let total = random + TimeConstants.baseline
            length = TimeInterval(minutes: total)
        }
        
        return length
    }
    
}
