// ViewController.swift
// Created by Nate Birkholz

import UIKit
import UserNotifications

class ViewController: UIViewController {
    let nextButton = UIButton(frame: .zero)
    let snoozeButton = UIButton(frame: .zero)
    let stopButton = UIButton(frame: .zero)
    let stack = UIStackView(frame: .zero)
    
    var reminder: Reminder?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.setTitle("Start Next", for: .normal)
        snoozeButton.setTitle("Snooze", for: .normal)
        stopButton.setTitle("Cancel", for: .normal)
        
        nextButton.setTitleColor(.black, for: .normal)
        snoozeButton.setTitleColor(.white, for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        
        nextButton.titleLabel?.textAlignment = .center
        snoozeButton.titleLabel?.textAlignment = .center
        stopButton.titleLabel?.textAlignment = .center
        
        nextButton.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
        snoozeButton.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
        stopButton.backgroundColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        
        nextButton.layer.cornerRadius = 16.0
        snoozeButton.layer.cornerRadius = 16.0
        stopButton.layer.cornerRadius = 16.0
        
        nextButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        snoozeButton.addTarget(self, action: #selector(snooze), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .equalCentering
        stack.alignment = .center
        
        stack.addArrangedSubview(nextButton)
        stack.addArrangedSubview(snoozeButton)
        stack.addArrangedSubview(stopButton)
        
        for subview in stack.arrangedSubviews {
            subview.widthAnchor.constraint(equalToConstant: 256.0).isActive = true
        }
        
        layoutStackView(stack)
        setButtonsState()
    }

    func wiewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setButtonsState()
    }
        
    func setButtonsState() {
        guard let timer = reminder else {
            nextButton.isHidden = false
            snoozeButton.isHidden = true
            stopButton.isHidden = true
            
            stack.layoutSubviews()
            
            return
        }
        
        switch timer.state {
        case .none:
            nextButton.isHidden = false
            snoozeButton.isHidden = true
            stopButton.isHidden = true
        case .running:
            nextButton.isHidden = true
            snoozeButton.isHidden = true
            stopButton.isHidden = false
        case .alerting:
            nextButton.isHidden = false
            snoozeButton.isHidden = false
            stopButton.isHidden = false
        case .snoozed:
            nextButton.isHidden = true
            snoozeButton.isHidden = true
            stopButton.isHidden = false
        }
        
        stack.layoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { maybeApproved, maybeError in
            print(maybeApproved)
        }
    }
    
    func layoutStackView(_ stackView: UIStackView) {
        view.addSubview(stackView)
        
        let constraints: [NSLayoutConstraint] = [
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24.0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 256.0),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24.0),
            stackView.heightAnchor.constraint(equalToConstant: 128.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func start() {
        let timer = Reminder()
        reminder = timer
        reminder?.start()
        setButtonsState()
    }
    
    @objc func snooze() {
        reminder?.snooze(completionHandler: {
            setButtonsState()
        })
    }
    
    @objc func stop() {
        reminder?.cancel()
        reminder = nil
        setButtonsState()
    }

}

