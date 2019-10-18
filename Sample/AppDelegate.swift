//
//  AppDelegate.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import Ballcap

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        FirebaseApp.configure()

        self.window = UIWindow(frame: UIScreen.main.bounds)

        guard let user: FirebaseAuth.User = Auth.auth().currentUser else {
            Auth.auth().signInAnonymously { [weak self] (result, error) in
                if let error = error {
                    print(error)
                    return
                }
                let userReference: DocumentReference = Firestore.firestore().document("/user/\(result!.user.uid)")

                print("**************************************")
                print("YOUR ID: ", userReference.documentID)
                print("**************************************")
                userReference.setData([:]) { _ in
                    let viewController: BoxViewController = BoxViewController(userReference: userReference)
                    let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)

                    let forumViewController: ForumViewController = ForumViewController(userReference: userReference)
                    let forumNavigationController: UINavigationController = UINavigationController(rootViewController: forumViewController)
                    let tabbarController: UITabBarController = UITabBarController(nibName: nil, bundle: nil)
                    tabbarController.setViewControllers([navigationController, forumNavigationController], animated: true)
                    self?.window?.rootViewController = tabbarController
                    self?.window?.makeKeyAndVisible()
                }
            }
            return true
        }

        print("**************************************")
        print("YOUR ID: ", user.uid)
        print("**************************************")

//        Document<Member>.get(id: user.uid) { (user, error) in
//            if user == nil {
//                _ = try! Auth.auth().signOut()
//            }
//        }
        let userReference: DocumentReference = Firestore.firestore().document("/user/\(user.uid)")
        let viewController: BoxViewController = BoxViewController(userReference: userReference)
        let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)
//        navigationController.navigationBar.isTranslucent = false
        let forumViewController: ForumViewController = ForumViewController(userReference: userReference)
        let forumNavigationController: UINavigationController = UINavigationController(rootViewController: forumViewController)
        let tabbarController: UITabBarController = UITabBarController(nibName: nil, bundle: nil)
        tabbarController.setViewControllers([navigationController, forumNavigationController], animated: true)
        self.window?.rootViewController = tabbarController
        self.window?.makeKeyAndVisible()

        return true
    }
}

