// InitialViewController.swift
// Created by Nate Birkholz

import UIKit
import UserNotifications

enum InitialViewError: Error {
    case hydrationError
    case unhandledState
}

class InitialViewController: UIViewController {
    let nextButton = UIButton(frame: .zero)
    let snoozeButton = UIButton(frame: .zero)
    let stopButton = UIButton(frame: .zero)
    let stack = UIStackView(frame: .zero)
    let bellView = UIImageView(frame: .zero)
    
    let debugger = Debugger()
    
    var viewModel = InitialViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "viewBackground")
        debugger.enabled = false
        
        setupButton(nextButton, withTitle: "GO!", withColor: .white, backgroundColor: .buttonStart)
        setupButton(snoozeButton, withTitle: "Snooze", withColor: .white, backgroundColor: .buttonSnooze)
        setupButton(stopButton, withTitle: "Stop!", withColor: .white, backgroundColor: .buttonStop)
        
        nextButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        snoozeButton.addTarget(self, action: #selector(snooze), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        layout()
    }
    
    func wiewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugger.log("ViewWillAppear")
        awake()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        debugger.log("ViewDidAppear")
        alertIfNecessary()
    }
    
    func awake() {
        Task {
            await hydrate()
            await checkForFinished()
            setButtonsState()
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
        guard let reminder = viewModel.reminder else {
            nextButton.isHidden = false
            snoozeButton.isHidden = true
            stopButton.isHidden = true
            stack.layoutSubviews()
            return
        }
        
        switch reminder.reminderData.reminderState {
        case .none:
            nextButton.isHidden = false
            snoozeButton.isHidden = true
            stopButton.isHidden = true
        case .running, .snoozed:
            nextButton.isHidden = true
            snoozeButton.isHidden = true
            stopButton.isHidden = false
        case .alerting:
            nextButton.isHidden = false
            snoozeButton.isHidden = false
            stopButton.isHidden = false
        }
        
        stack.layoutSubviews()
    }
    
    func layout() {
        layoutStackView()
        layoutBellView()
        setButtonsState()
        layoutDebugView()
    }
    
    func layoutStackView() {
        view.addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 12.0
        
        stack.addArrangedSubview(nextButton)
        stack.addArrangedSubview(snoozeButton)
        stack.addArrangedSubview(stopButton)
        
        for subview in stack.arrangedSubviews {
            subview.widthAnchor.constraint(equalToConstant: 224.0).isActive = true
        }
        
        let constraints: [NSLayoutConstraint] = [
            stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24.0),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 128.0),
            stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24.0),
            stack.heightAnchor.constraint(equalToConstant: 256.0)
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
    
    func layoutDebugView() {
        if debugger.enabled {
            debugger.textView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(debugger.textView)
            debugger.clear()
            
            let constraints: [NSLayoutConstraint] = [
                debugger.textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16.0),
                debugger.textView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16.0),
                debugger.textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0),
                debugger.textView.bottomAnchor.constraint(equalTo: bellView.topAnchor, constant: -16.0)
            ]
            
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    func checkForFinished() async {
        let now = Date()
        
        if let reminder = viewModel.reminder,
           let fireTime = reminder.reminderData.endTime,
           fireTime < now.timeIntervalSinceReferenceDate {
            reminder.didFire()
        }
    }
}

// MARK: Hydration
extension InitialViewController {
    func hydrate() async {
        if viewModel.reminder == nil && Serializer.dataExists {
            do {
                let data = try Serializer.loadData()
                if let data = data {
                    viewModel.setReminder(Reminder(data: data))
                    debugger.log("Hydrate hydrate")
                } else {
                    debugger.log("Hydrate create")
                    viewModel.setError(InitialViewError.hydrationError)
                }
            } catch let error {
                viewModel.setError(error)
            }
        }
    }
}

// MARK: Button controls
extension InitialViewController {
    @objc func start() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                requestAuthorization()
            case .denied:
                remindAuthorization()
            case .ephemeral, .provisional, .authorized:
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                viewModel.reminder = Reminder()
                go()
            @unknown default:
                viewModel.loadingError = InitialViewError.unhandledState
            }
        }
    }
    
    func go() {
        Task {
            await viewModel.reminder?.start()
            debugger.log("Starting...")
            setButtonsState()
            
            if let data = viewModel.reminder?.reminderData {
                do {
                    try Serializer.saveData(data)
                } catch let error {
                    viewModel.loadingError = error
                    alertIfNecessary()
                }
            }
        }
    }
    
    @objc func snooze() {
        Task {
            await viewModel.reminder?.snooze()
            setButtonsState()
            
            if let data = viewModel.reminder?.reminderData {
                do {
                    try Serializer.saveData(data)
                } catch let error {
                    viewModel.loadingError = error
                    alertIfNecessary()
                }
            }
        }
    }
    
    @objc func stop() {
        Task {
            await viewModel.reminder?.cancel()
            viewModel.setReminder(nil)
            setButtonsState()
            debugger.log("Stopped")
        }
    }
}

// MARK: User Alerts
extension InitialViewController {
    func alertForError(error: Error) {
        let title: String = "Alert"
        let message: String
        
        if let error = error as? SerializationError {
            switch error {
            case .encodingError(let string):
                message = "Unable to save reminder: \(string)."
            case .loadingError:
                message = "Unable to load reminder: No data found."
            case .decodingError(let string):
                message = "Unable to load reminder: \(string)."
            }
        } else if let error = error as? InitialViewError {
            switch error {
            case .hydrationError:
                message = "Unable to load reminder: Data initialization failed."
            case .unhandledState:
                message = "Could not determine authorization state."
            }
        } else {
            message = "Unknown Error. This is fine."
        }
        
         let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.setError(nil)
        }
        
        postAlert(title: title, message: message, actions: [okAction])
    }
    
    func postAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func alertIfNecessary() {
        if let error = viewModel.loadingError {
            alertForError(error: error)
        }
    }
}

// MARK: Notification Status
extension InitialViewController {
    func requestAuthorization() {
        let title = "Authorization Required"
        let message = "Reminderer needs authorization to show you a notification when the timer is up. Please allow Reminderer to alert you to use its functionality."
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] approved, maybeError in
                if approved {
                    self?.start()
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        postAlert(title: title, message: message, actions: [okAction, cancelAction])
    }
    
    func remindAuthorization() {
        let title = "Authorization Required"
        let message = "You previously denied Reminderer permission to show you alerts. Would you like to turn on notifications now?"
        let settingsAction = UIAlertAction(title: "Open Settings", style: .default) { (_) -> Void in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        
        let laterAction = UIAlertAction(title: "Later", style: .cancel, handler: nil)
        
        postAlert(title: title, message: message, actions: [settingsAction, laterAction])
    }
}
