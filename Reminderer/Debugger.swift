// Debugger.swift
// Created by Nate Birkholz

import UIKit

class Debugger {
    let textView = UITextView(frame: .zero)
    var enabled = false
    
    init() {
        clear()
    }
    
    func log(_ string: String) {
        if enabled {
            textView.text.append("\n")
            textView.text.append(string)
        }
    }
    
    func clear() {
        if enabled {
            textView.text = "Initalized"
        }
    }
    
}
