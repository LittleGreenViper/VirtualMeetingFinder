/*
 © Copyright 2024-2026, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Main Scene Delegate -
/* ###################################################################################################################################### */
/**
 This class has the Scene Delegate functionality.
 */
class VMF_SceneDelegate: UIResponder, UIWindowSceneDelegate {
     /* ################################################################## */
     /**
      If it's been over this many seconds since our last load, we force a new load, the next time we open.
      */
     static let forceReloadDelayInSeconds = TimeInterval(60 * 60 * 4)
     
     /* ################################################################## */
     /**
      This is set to the last time we loaded.
      While the app is up in the foreground, we won't be forcing a reload, but we will, if it enters the background, then comes back.
      */
     static var lastReloadTime = Date.distantPast
     
     /* ################################################################## */
     /**
      */
     static var urlMeetingID = Int(0)

     /* ################################################################## */
     /**
      The window object for this scene.
      */
     var window: UIWindow?

     /* ################################################################## */
     /**
      Keeps the configured launch screen visible over the main screen's initial layout.
      */
     private var _launchScreenWindow: UIWindow?

     /* ################################################################## */
     /**
      Reveals the main screen on the next display refresh after its startup layout.
      */
     private var _launchScreenDisplayLink: CADisplayLink?
     
     /* ################################################################## */
     /**
      Quick access to the scene delegate object.
      */
     static weak var sceneDelegateInstance: VMF_SceneDelegate?

     /* ################################################################## */
     /**
      Called after the scene went into the background.
      
      We use this to set the search screen to today/now.
      
      - parameter: The scene instance (ignored).
      */
     func sceneDidEnterBackground(_: UIScene) {
          Self.lastReloadTime = .now
     }

     /* ################################################################## */
     /**
      Releases any startup cover when its scene is disconnected.

      - parameter: The scene instance (ignored).
      */
     func sceneDidDisconnect(_: UIScene) {
          _removeLaunchScreen()
     }
     
     /* ################################################################## */
     /**
      Called after the scene is entering into the foreground.
      
      We use this to set the search screen to today/now.
      
      - parameter: The scene instance (ignored).
      */
     func sceneWillEnterForeground(_: UIScene) {
          Self.sceneDelegateInstance = self
          if nil == VMF_AppDelegate.openMeeting {
               VMF_AppDelegate.mainScreenController?.isThrobbing = true
               VMF_AppDelegate.virtualService?.refreshCaches() { _ in
                    VMF_AppDelegate.mainScreenController?.isThrobbing = false
                    VMF_AppDelegate.mainScreenController?.openTo()
                    self.window?.setNeedsLayout()
               }
          } else {
               self.window?.setNeedsLayout()
          }
     }
     
     /* ################################################################## */
     /**
      Called when the app is foregrounded via a URL.
      
      - parameter: The scene instance (ignored).
      - parameter openURLContexts: The Opening URL contexts (as a set).
      */
     func scene(_: UIScene, openURLContexts inURLContexts: Set<UIOpenURLContext>) {
          inURLContexts.forEach { resolveURL($0.url) }
     }
     
     /* ################################################################## */
     /**
      Called when the app is opened via a URL from a "cold start."
      - parameter inScene: The scene instance.
      - parameter willConnectTo: The session being connected (ignored).
      - parameter inConnectionOptions: This contains the options, among which, is the URL context.
      */
     func scene(_ inScene: UIScene, willConnectTo: UISceneSession, options inConnectionOptions: UIScene.ConnectionOptions) {
          if let windowScene = inScene as? UIWindowScene,
             let storyboardName = Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String,
             let launchController = UIStoryboard(name: storyboardName, bundle: nil).instantiateInitialViewController() {
               let launchWindow = UIWindow(windowScene: windowScene)
               launchWindow.windowLevel = UIWindow.Level(rawValue: (window?.windowLevel ?? .normal).rawValue + 1)
               launchWindow.rootViewController = launchController
               _launchScreenWindow = launchWindow
               launchWindow.isHidden = false
          }

          guard let url = inConnectionOptions.userActivities.first?.webpageURL ?? inConnectionOptions.urlContexts.first?.url else { return }
          resolveURL(url)
     }
     
     /* ################################################################## */
     /**
      Called when the app is opened via a URL (and launched).
      - parameter inScene: The scene instance (ignored).
      - parameter inUserActivity: The activity being continued.
      */
     func scene(_ inScene: UIScene, continue inUserActivity: NSUserActivity) {
          guard let url = inUserActivity.webpageURL else { return }
          resolveURL(url)
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_SceneDelegate {
     /* ################################################################## */
     /**
      Finishes startup after initial loading and layout of the main screen and navigation bar.
      */
     func finishLaunching() {
          guard nil != _launchScreenWindow,
                nil == _launchScreenDisplayLink
          else { return }

          window?.layoutIfNeeded()
          let displayLink = CADisplayLink(target: self, selector: #selector(_launchScreenFrameDidRender))
          _launchScreenDisplayLink = displayLink
          displayLink.add(to: .main, forMode: .common)
     }

     /* ################################################################## */
     /**
      Dissolves the startup cover once the completed main screen is ready for the next frame.

      - parameter inDisplayLink: The display link that waits for the main screen's first frame.
      */
     @objc private func _launchScreenFrameDidRender(_ inDisplayLink: CADisplayLink) {
          inDisplayLink.invalidate()
          guard let launchWindow = _launchScreenWindow else {
               _removeLaunchScreen()
               return
          }

          UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
               launchWindow.alpha = 0
          } completion: { [weak self] _ in
               guard self?._launchScreenWindow === launchWindow else { return }
               self?._removeLaunchScreen()
          }
     }

     /* ################################################################## */
     /**
      Releases the startup cover and its display link.
      */
     private func _removeLaunchScreen() {
          _launchScreenDisplayLink?.invalidate()
          _launchScreenDisplayLink = nil
          _launchScreenWindow?.isHidden = true
          _launchScreenWindow = nil
     }

     /* ################################################################## */
     /**
      This will set the static property to a given meeting ID, if it is provided in the URI.
      
      - parameter inURL: The URL to resolve.
      */
     func resolveURL(_ inURL: URL) {
          if let statusString = inURL.query(),
             let meetingID = Int(statusString),
             0 < meetingID {
               Self.urlMeetingID = meetingID
          }
     }
}

