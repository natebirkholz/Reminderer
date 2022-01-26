// Reminder.swift
// Created by Nate Birkholz

import Foundation
import AVFoundation
import UserNotifications
import UIKit

enum ReminderState: Int, Codable {
    case none = 0, running, snoozed, alerting
}

class Reminder {
    private(set) var reminderData: ReminderData
    
    init() {
        let timer = Reminder.defaultTime
        let snooze = Reminder.defaultSnooze
        reminderData = ReminderData(timer: timer, snooze: snooze)
    }
    
    init(data: ReminderData) {
        reminderData = data
    }
    
    init(time: TimeInterval, snooze: TimeInterval) {
        reminderData = ReminderData(timer: time , snooze: snooze)
    }
    
    init(timerBaseline: Int,
         timerLowVariance: Int,
         timerHighVariance: Int,
         snoozeBaseline: Int,
         snoozeLowVariance: Int,
         snoozeHighVariance: Int) {
        
        let timer = TimeInterval.randomizedIntervalWith(baseline: timerBaseline, lowVariance: timerLowVariance, highVariance: timerHighVariance)
        let snooze = TimeInterval.randomizedIntervalWith(baseline: snoozeBaseline, lowVariance: snoozeLowVariance, highVariance: snoozeHighVariance)
        
        reminderData = ReminderData(timer: timer, snooze: snooze)
    }
    
    func didFire() {
        reminderData.reminderState = .alerting
    }
    
    func start() {
        let interval = reminderData.timer
        fire(after: interval)
        reminderData.reminderState = .running
    }
    
    func snooze(completionHandler: (() -> ())) {
        let interval = reminderData.snooze
        fire(after: interval)
        reminderData.reminderState = .snoozed
        completionHandler()
    }
    
    func cancel() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderData.id])
        if let time = reminderData.runtime {
            let minutes = Int(round(time / 60.0))
            notifyCanceled(for: minutes)
        }
        reminderData.reminderState = .none
        Serializer.clear()
    }
    
    private func fire(after timeInterval: TimeInterval) {
        let content = self.makeNotificationContent(with: timeInterval)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: reminderData.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        
        let end = Date().timeIntervalSinceReferenceDate + timeInterval
        reminderData.endTime = end
    }
    
    private func makeNotificationContent(with timeInterval: TimeInterval) -> UNNotificationContent {
        let minutes = Int(round(timeInterval / 60.0))
        let content = UNMutableNotificationContent()
        content.title = "It's that time!"
        content.body = "Time to take a break. It has been \(minutes) minutes."
        let name = UNNotificationSoundName("Kazoos.wav")
        let sound = UNNotificationSound(named: name)
        content.sound = sound
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = Reminder.threadIdentifier
        
        return content
    }
    
    func notifyCanceled(for minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Canceled"
        content.body = "Reminderer canceled before \(minutes) minutes elapsed."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

extension Reminder {
    static var threadIdentifier: String = "com.natebirkholz.reminderer.notifications.threadIdentifier"
    
    static var defaultTime: TimeInterval {
        return TimeInterval.randomizedIntervalWith(baseline: 20, lowVariance: 5, highVariance: 25)
    }
    
    static var defaultSnooze: TimeInterval {
        return TimeInterval.randomizedIntervalWith(baseline: 5, lowVariance: 1, highVariance: 6)
    }
}
