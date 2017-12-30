//
//  AppDelegate.swift
//  howalarming
//
//  Created by Jethro Carr on 20/02/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase

// The various states that our alarm can be in (for the purposes of arm/disarming).
enum AlarmStates {
    case unknown
    case armed
    case disarmed
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    // We set this with the details we extract from FCM and the settings plist file and use whenever generating messages
    var gcmSenderID: String?
    var registrationToken: String?
    
    // We track alarm state in-app, but this also gets push from the server everytime the app view is
    // opened to check the state, since it's possible the app has missed some messages.
    var stateArmed = AlarmStates.unknown
    
    // Keys used to label different internal messages between AppDelegate and ViewControllers
    let registrationKey = "onRegistrationCompleted"
    let messageKey = "onMessageReceived"
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Here we are extracting out the GCM SENDER ID from the Google PList file. There used to be an easy way
        // to get this with GCM, but it's non-obvious with FCM so we're just going to read the plist file.
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            let dictRoot = NSDictionary(contentsOfFile: path)
            if let dict = dictRoot {
                if let gcmSenderId = dict["GCM_SENDER_ID"] as? String {
                    self.gcmSenderID = gcmSenderId
                }
            }
        }
        
        // Configure FCM and other Firebase APIs with a single call.
        FirebaseApp.configure()
        
        // Setup FCM messaging
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        // Trigger when FCM establishes it's direct connection. We want to know this to avoid race conditions where we
        // try to post upstream messages before the direct connection is ready... which kind of sucks.
        NotificationCenter.default.addObserver(self, selector: #selector(onMessagingDirectChannelStateChanged(_:)), name: .MessagingConnectionStateChanged, object: nil)
        
        // Trigger if we fail to send a message upstream for any reason.
        NotificationCenter.default.addObserver(self, selector: #selector(onMessagingUpstreamFailure(_:)), name: .MessagingSendError, object: nil)
    
        // Register for remote notifications (APNS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            // We don't have errors, nothing to do right? ;-)
        }
        application.registerForRemoteNotifications()
    
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Nothing going on right now.
    }
    

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error ) {
        print("Registration for remote notification failed with error: \(error.localizedDescription)")
        
        let userInfo = ["error": error.localizedDescription]
        let notificationName = Notification.Name(self.registrationKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        print("Remote notification received: \(userInfo)")
        
        // Pass the recieved message to the view controller
        let notificationName = Notification.Name(self.messageKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler handler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        print("Remote notification received w/ handler: \(userInfo)")
        
        // Handle the received message by passing on to the ViewController.
        let notificationName = Notification.Name(self.messageKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
        
        // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
        handler(UIBackgroundFetchResult.noData);
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        // Only invoked when recieving an FCM direct channel push message. Can only occur when the app is running in
        // the foreground, and only after the inital startup and establishment of the direct channel connection has
        // been completed.
        print("FCM direct channel push message recieved")
        
        let notificationName = Notification.Name(self.messageKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: remoteMessage.appData)
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        // This is fired whenever FCM gets a new app token.
        // Deprecated, but MessagingDelegate protocol demands that we have it! >:-(
        print("Firebase registration token via deprecated refresh method: \(fcmToken)")
        self.registrationToken = fcmToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        // This is fired on inital startup on the application, or when the application changes.
        print("Firebase registration token: \(fcmToken)")
        self.registrationToken = fcmToken
    }
    
    @objc
    func onMessagingDirectChannelStateChanged(_ notification: Notification) {
        // This is our own function listen for the direct connection to be established.
        print("Is FCM Direct Channel Established: \(Messaging.messaging().isDirectChannelEstablished)")
        
        if (Messaging.messaging().isDirectChannelEstablished) {
            // Set the FCM token. Given that a direct channel has been established, it kind of implies that this
            // must be available to us..
            if self.registrationToken == nil {
                if let fcmToken = Messaging.messaging().fcmToken {
                    self.registrationToken = fcmToken
                    print("Firebase registration token: \(fcmToken)")
                }
            }
            
            // Send a "ping" message to the HowAlarming GCM/FCM server. This is required to ensure that the server
            // becomes aware of our device and can register it. Technically, this should be persisted by the server
            // but we haven't implemented any kind of persistency so for now we rely on this ping for the registration
            // to take place.
            //
            // The ping also performs another vital role, which is that it triggers a silent status message being
            // sent back advising the current alarm status (eg armed/disarmed), which we need for UI controls to be
            // accurate.
        
            let messageId = ProcessInfo().globallyUniqueString
            let messageData: [String: String] = [
                "registration_token": self.registrationToken!,
                "command": "ping",
                "timestamp": String( Date().timeIntervalSince1970 / 1000 )
            ]
            let messageTo: String = self.gcmSenderID! + "@gcm.googleapis.com"
            let ttl: Int64 = 0 // Setting to zero means if it can't complete delivery immediately, it abandons the message
        
            print("Sending ping message to FCM server: \(messageTo)")
    
            Messaging.messaging().sendMessage(messageData, to: messageTo, withMessageID: messageId, timeToLive: ttl)
        }
    }
    
    @objc
    func onMessagingUpstreamFailure(_ notification: Notification) {
        // FCM tends not to give us any kind of useful message here, but at least we now know it failed for when we start debugging it.
        print("A failure occurred when attempting to send a message upstream via FCM")
    }
    
}
