// InitialViewModel.swift
// Created by Nate Birkholz

import Foundation

struct InitialViewModel {
    var reminder: Reminder?
    var loadingError: Error?
    
    mutating func setReminder(_ reminder: Reminder?) {
        self.reminder = reminder
    }
    
    mutating func setError(_ loadingError: Error?) {
        self.loadingError = loadingError
    }
}
