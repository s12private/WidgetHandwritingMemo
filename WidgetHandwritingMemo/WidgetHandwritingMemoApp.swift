//
//  WidgetHandwritingMemoApp.swift
//  WidgetHandwritingMemo
//
//  Created by 松中誉生 on 2020/09/07.
//

import SwiftUI

import UIKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}

@main
struct WidgetHandwritingMemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("memos", store: UserDefaults(suiteName: "group.shigeki.work.WidgetHandwritingMemo"))
    var memoManagerData:Data = Data()
    
    @AppStorage("images", store: UserDefaults(suiteName: "group.shigeki.work.WidgetHandwritingMemo"))
    var imageManagerData:Data = Data()
    
    var body: some Scene {
        WindowGroup {
            ContentView(memoManagerData: $memoManagerData, data:DataObservable(memoManagerData: $memoManagerData, imageManagerData: $imageManagerData))
                .onOpenURL { (url) in
                    print(url)
                }
                .statusBar(hidden: true)
        }
    }
}
