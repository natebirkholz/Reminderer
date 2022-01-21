// InitialViewController.swift
// Created by Nate Birkholz

import UIKit
import UserNotifications

class InitialViewController: UIViewController {
    let nextButton = UIButton(frame: .zero)
    let snoozeButton = UIButton(frame: .zero)
    let stopButton = UIButton(frame: .zero)
    let stack = UIStackView(frame: .zero)
    let bellView = UIImageView(frame: .zero)
    
    var reminder: Reminder?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "viewBackground")
        
        setupButton(nextButton, withTitle: "GO!", withColor: .white, backgroundColor: .buttonStart)
        setupButton(snoozeButton, withTitle: "Snooze...", withColor: .white, backgroundColor: .buttonSnooze)
        setupButton(stopButton, withTitle: "Stop!", withColor: .white, backgroundColor: .buttonStop)
        
        nextButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        snoozeButton.addTarget(self, action: #selector(snooze), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        layoutStackView(stack)
        layoutBellView()
        setButtonsState()
    }
    
    func wiewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setButtonsState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { maybeApproved, maybeError in
            print(maybeApproved)
        }
    }
    
    func setupButton(_ button: UIButton,
                     withTitle title: String,
                     withColor color: UIColor,
                     backgroundColor: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 16.0
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
    
    func layoutStackView(_ stackView: UIStackView) {
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        
        stackView.addArrangedSubview(nextButton)
        stackView.addArrangedSubview(snoozeButton)
        stackView.addArrangedSubview(stopButton)
        
        for subview in stackView.arrangedSubviews {
            subview.widthAnchor.constraint(equalToConstant: 224.0).isActive = true
        }
        
        let constraints: [NSLayoutConstraint] = [
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24.0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 128.0),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24.0),
            stackView.heightAnchor.constraint(equalToConstant: 192.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func layoutBellView() {
        bellView.translatesAutoresizingMaskIntoConstraints = false
        bellView.image = UIImage(named: "roundedBell")
        bellView.contentMode = .scaleAspectFit
        bellView.alpha = 0.6
        view.addSubview(bellView)
        
        let constraints: [NSLayoutConstraint] = [
            bellView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bellView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32.0),
            bellView.widthAnchor.constraint(equalToConstant: 64.0),
            bellView.heightAnchor.constraint(equalToConstant: 64.0)
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
