// TimeInterval+Minutes.swift
// Created by Nate Birkholz

import Foundation

extension TimeInterval {
    init(minutes: Double) {
        let seconds = minutes * Double(60.0)
        self = TimeInterval(seconds)
    }
}
