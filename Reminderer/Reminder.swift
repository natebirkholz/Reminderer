// Reminder.swift
// Created by Nate Birkholz

import Foundation
import AVFoundation
import UserNotifications

enum TimerState {
    case none, running, snoozed, alerting
}

class Reminder {
    private var reminder: Timer?
    private(set) var state: TimerState = .none
    let id = UUID().uuidString
    
    let timerTime: BoundedTime
    let snoozeTime: BoundedTime
    
    init() {
        timerTime = BoundedTime.defaultTime
        snoozeTime = BoundedTime.defaultSnooze
    }
    
    init(time: BoundedTime, snooze: BoundedTime) {
        timerTime = time
        snoozeTime = snooze
    }
    
    init(timerBaseline: Int,
         timerLowVariance: Int,
         timerHighVariance: Int,
         snoozeBaseline: Int,
         snoozeLowVariance: Int,
         snoozeHighVariance: Int) {
        
        timerTime = BoundedTime(baseline: timerBaseline, lowVariance: timerLowVariance, highVariance: timerHighVariance)
        snoozeTime = BoundedTime(baseline: snoozeBaseline, lowVariance: snoozeLowVariance, highVariance: snoozeHighVariance)
    }
    
    func start() {
        let interval = timerTime.randomized
        fire(after: interval)
        state = .running
    }
    
    func snooze(completionHandler: (() -> ())) {
        let interval = snoozeTime.randomized
        fire(after: interval)
        state = .snoozed
    }
    
    @objc func fire(after timeInterval: TimeInterval) {
        let minutes = Int(round(timeInterval / 60.0))
        let content = UNMutableNotificationContent()
        content.title = "It's that time!"
        content.body = "Time to tap a button. It has been \(minutes) minutes."
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
    
}
