// UIColor+ProjectColors.swift
// Created by Nate Birkholz

import UIKit

extension UIColor {
    static var buttonStart: UIColor {
        UIColor.eightBitColorWith(R: 255, G: 212, B: 0)
    }
    static var buttonSnooze: UIColor {
        UIColor.eightBitColorWith(R: 255, G: 159, B: 4)
    }
    static var buttonStop: UIColor {
        UIColor.eightBitColorWith(R: 255, G: 100, B: 26)
    }
    static var viewBackground: UIColor {
        UIColor.eightBitColorWith(R: 121, G: 227, B: 249)
    }
    
    static func eightBitColorWith(R red: Int, G green: Int, B blue: Int, A alpha: CGFloat = 1.0) -> UIColor {
        let r = CGFloat(red.doubleValue / 255.0)
        let g = CGFloat(green.doubleValue / 255.0)
        let b = CGFloat(blue.doubleValue / 255.0)
        
        let color = UIColor(red: r, green: g, blue: b, alpha: alpha)
        return color
    }
}
