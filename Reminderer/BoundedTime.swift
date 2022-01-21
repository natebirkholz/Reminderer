// BoundedTime.swift
// Created by Nate Birkholz

import Foundation
import AVFAudio

struct BoundedTime {
    let baseline: Int
    let lowVariance: Int
    let highVariance: Int
    
    var randomizedInterval: TimeInterval {
        let variance = Int.random(in: lowVariance...highVariance)
        let total = baseline + variance
        
        return TimeInterval(minutes: total.doubleValue)
    }
}

extension BoundedTime {
    static var defaultTime: BoundedTime {
        return BoundedTime(baseline: 20, lowVariance: 5, highVariance: 25)
    }
    
    static var defaultSnooze: BoundedTime {
        return BoundedTime(baseline: 5, lowVariance: 1, highVariance: 6)
    }
}
