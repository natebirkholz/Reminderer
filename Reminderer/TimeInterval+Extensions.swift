// TimeInterval+Extensions.swift
// Created by Nate Birkholz

import Foundation

extension TimeInterval {
    init(minutes: Double) {
        let seconds = minutes * Double(60.0)
        self = TimeInterval(seconds)
    }
    
    static func randomizedIntervalWith(baseline: Int, lowVariance: Int, highVariance: Int) -> TimeInterval {
        let variance = Int.random(in: lowVariance...highVariance)
        let total = baseline + variance
        
        return TimeInterval(minutes: total.doubleValue)
    }
    
    static var distantPast: TimeInterval {
        return Date.distantPast.timeIntervalSinceReferenceDate
    }
}
