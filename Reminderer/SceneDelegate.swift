// SceneDelegate.swift
// Created by Nate Birkholz

import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        UNUserNotificationCenter.current().delegate = self
        guard let _ = (scene as? UIWindowScene) else { return }
    }
        
    func sceneWillEnterForeground(_ scene: UIScene) {
        if let vc = window?.rootViewController as? InitialViewController {
            vc.awake()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let vc = window?.rootViewController as? InitialViewController {
            vc.alertIfNecessary()
        }
    }
}

extension SceneDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner])
    }
}
