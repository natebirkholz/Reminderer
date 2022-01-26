// InitialViewController.swift
// Created by Nate Birkholz

import UIKit
import UserNotifications

enum InitialViewError: Error {
    case hydrationError
}

class InitialViewController: UIViewController {
    let nextButton = UIButton(frame: .zero)
    let snoozeButton = UIButton(frame: .zero)
    let stopButton = UIButton(frame: .zero)
    let stack = UIStackView(frame: .zero)
    let bellView = UIImageView(frame: .zero)
    
    var viewModel = InitialViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "viewBackground")
        
        setupButton(nextButton, withTitle: "GO!", withColor: .white, backgroundColor: .buttonStart)
        setupButton(snoozeButton, withTitle: "Snooze...", withColor: .white, backgroundColor: .buttonSnooze)
        setupButton(stopButton, withTitle: "Stop!", withColor: .white, backgroundColor: .buttonStop)
        
        nextButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        snoozeButton.addTarget(self, action: #selector(snooze), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        layout()
        
        Task {
            await hydrate()
            await checkForFinished()
            setButtonsState()
        }
    }
    
    func wiewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setButtonsState()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        if let error = viewModel.loadingError {
            alertForError(error: error)
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
    
    func layout() {
        layoutStackView()
        layoutBellView()
        setButtonsState()
    }
    
    func layoutStackView() {
        view.addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .equalCentering
        stack.alignment = .center
        
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
                } else {
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
            if settings.authorizationStatus == .notDetermined {
                requestAuthorization()
            } else if settings.authorizationStatus == .denied {
                remindAuthorization()
            } else {
                viewModel.setReminder(Reminder())
                viewModel.reminder?.start()
                setButtonsState()
            }
        }
        
    }
    
    @objc func snooze() {
        viewModel.reminder?.snooze(completionHandler: {
            setButtonsState()
        })
    }
    
    @objc func stop() {
        Task {
            await viewModel.reminder?.cancel()
            viewModel.setReminder(nil)
            setButtonsState()
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
