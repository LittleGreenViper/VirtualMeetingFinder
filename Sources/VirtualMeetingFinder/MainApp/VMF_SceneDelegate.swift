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
      The background interval after which the main screen considers its meeting collection stale (four hours).
      */
     static let forceReloadDelayInSeconds = TimeInterval(60 * 60 * 4)
     
     /* ################################################################## */
     /**
      Records entry into the background. Distant future suppresses age-based reloads in the foreground.
      */
     static var lastReloadTime = Date.distantPast
     
     /* ################################################################## */
     /**
      The pending meeting ID from an incoming link; zero means no meeting is pending.
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

     /// Serializes link navigation while dismissing an existing presentation.
     private var _isOpeningLinkedMeeting = false

     /// Reads the latest full collection when navigation is ready. Keeping the
     /// source replaceable also allows navigation tests to supply offline records.
     var meetingSource: () -> [MeetingInstance]? = {
          VMF_AppDelegate.virtualService?.meetings.map(\.meeting)
     }
     
     /* ################################################################## */
     /**
      Quick access to the scene delegate object.
      */
     static weak var sceneDelegateInstance: VMF_SceneDelegate?

     /* ################################################################## */
     /**
      Called after the scene went into the background.
      
      Dismisses the day/time popover before suspension and records when the app was backgrounded.
      
      The scene parameter is unused.
      */
     func sceneDidEnterBackground(_: UIScene) {
          VMF_AppDelegate.mainScreenController?.dismissDayTimeSelectionPopover()
          Self.lastReloadTime = .now
     }

     /* ################################################################## */
     /**
      Releases any startup cover when its scene is disconnected.

      The scene parameter is unused.
      */
     func sceneDidDisconnect(_: UIScene) {
          _removeLaunchScreen()
     }
     
     /* ################################################################## */
     /**
      Called after the scene is entering into the foreground.
      
      We use this to show the meetings that are in progress, just like the Now button.
      
      The scene parameter is unused.
      */
     func sceneWillEnterForeground(_: UIScene) {
          Self.sceneDelegateInstance = self
          // Also finish any pending dismissal before the refresh hides the popover's navigation-bar anchor.
          VMF_AppDelegate.mainScreenController?.dismissDayTimeSelectionPopover()
          if nil == VMF_AppDelegate.openMeeting,
             let virtualService = VMF_AppDelegate.virtualService {
               VMF_AppDelegate.mainScreenController?.isThrobbing = true
               virtualService.refreshCaches() { _ in
                    VMF_AppDelegate.mainScreenController?.isThrobbing = false
                    VMF_AppDelegate.mainScreenController?.openTo(dayIndex: 0)
                    self.window?.setNeedsLayout()
                    self.openPendingMeeting()
               }
          } else {
               self.window?.setNeedsLayout()
          }
     }

     /// Retries a link delivered before the scene or its meeting collection was ready.
     func sceneDidBecomeActive(_: UIScene) {
          openPendingMeeting()
     }
     
     /* ################################################################## */
     /**
      Called when the app is foregrounded via a URL.
      
      - parameter inScene: The scene (unused).
      - parameter inURLContexts: The incoming URL contexts.
      */
     func scene(_ inScene: UIScene, openURLContexts inURLContexts: Set<UIOpenURLContext>) {
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
          Self.sceneDelegateInstance = self
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
          if inURL == VMF_WidgetStore.openAppURL {
               Self.urlMeetingID = 0
               return
          }
          guard let meetingID = VMF_MeetingLink.meetingID(in: inURL) else { return }
          Self.urlMeetingID = meetingID
          openPendingMeeting()
     }

     /// Opens a pending meeting from the full collection, independent of the current
     /// day, search, or service filter. A cold-start link stays queued until data and
     /// the embedded table are ready; a warm link replaces any existing inspector.
     func openPendingMeeting() {
          guard !_isOpeningLinkedMeeting, Self.urlMeetingID > 0,
                let main = VMF_AppDelegate.mainScreenController, !main.isThrobbing,
                let navigation = main.navigationController, navigation.viewIfLoaded?.window != nil,
                let table = main.tableDisplayController as? VMF_EmbeddedTableController,
                let meetings = meetingSource(), !meetings.isEmpty else { return }
          guard let meeting = meetings.first(where: { $0.id == Self.urlMeetingID }) else {
               Self.urlMeetingID = 0
               return
          }

          // Wait until UIKit can change the navigation stack without competing with
          // a presentation, swipe-back, or push already in progress.
          if let transition = navigation.transitionCoordinator {
               _isOpeningLinkedMeeting = true
               transition.animate(alongsideTransition: nil) { [weak self] _ in
                    DispatchQueue.main.async {
                         self?._isOpeningLinkedMeeting = false
                         self?.openPendingMeeting()
                    }
               }
               return
          }
          if navigation.presentedViewController != nil {
               _isOpeningLinkedMeeting = true
               navigation.dismiss(animated: false) { [weak self] in
                    self?._isOpeningLinkedMeeting = false
                    self?.openPendingMeeting()
               }
               return
          }

          // Clear before popping: the embedded table's appearance callback also
          // checks for pending links. This prevents opening the inspector twice.
          Self.urlMeetingID = 0
          if let inspector = navigation.topViewController as? VMF_MeetingInspectorViewController,
             inspector.meeting?.id == meeting.id { return }
          navigation.popToViewController(main, animated: false)
          table.selectMeeting(meeting)
     }
}

