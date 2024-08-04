/*
 © Copyright 2024, Little Green Viper Software Development LLC
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
import EventKitUI
import MapKit
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Custom Activity Class Base -
/* ###################################################################################################################################### */
/**
 We can present a custom activity, that allows the user to add the meeting to their calendar.
 */
class VMF_Base_Activity: UIActivity {
     /* ################################################################## */
     /**
      The controller that "owns" this instance.
      */
     weak var myController: VMF_MeetingInspectorViewController?
     
     /* ################################################################## */
     /**
      Initializer
      
      - parameter myController: The controller that "owns" this activity.
      - parameter actionButton: The action button for the screen. We use it to anchor an iPad popover (Can be omitted).
      */
     init(myController inMyController: VMF_MeetingInspectorViewController?) {
          myController = inMyController
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_Base_Activity {
     /* ################################################################## */
     /**
      The basic category for this activity (an action line).
      */
     override class var activityCategory: UIActivity.Category { .action }
}

/* ###################################################################################################################################### */
// MARK: - Custom Add To Calendar Activity Class -
/* ###################################################################################################################################### */
/**
 We can present a custom activity, that allows the user to add the meeting to their calendar.
 */
class VMF_AddToCalendar_Activity: VMF_Base_Activity {
     /* ################################################################## */
     /**
      The URL string, which is sent to Messages.
      */
     let meetingEvent: EKEvent?
     
     /* ################################################################## */
     /**
      Initializer
      
      - parameter meetingEvent: The event for this activity (Can be omitted).
      - parameter myController: The controller that "owns" this activity.
      - parameter actionButton: The action button for the screen. We use it to anchor an iPad popover (Can be omitted).
      */
     init(meetingEvent inMeetingEvent: EKEvent? = nil, myController inMyController: VMF_MeetingInspectorViewController? = nil) {
          meetingEvent = inMeetingEvent
          super.init(myController: inMyController)
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity {
     /* ################################################################## */
     /**
      The title string for this activity.
      */
     override var activityTitle: String? { "SLUG-ADD-TO-CALENDAR".localizedVariant }
     
     /* ################################################################## */
     /**
      The template image for the activity line.
      */
     override var activityImage: UIImage? { UIImage(systemName: "calendar.badge.plus") }
     
     /* ################################################################## */
     /**
      We have our own custom activity type.
      */
     override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("com.littlegreenviper.vmf.addToCalendar") }
     
     /* ################################################################## */
     /**
      We extract the event from the items, and return true.
      
      - parameter withActivityItems: The activity items (ignored).
      */
     override func canPerform(withActivityItems inActivityItems: [Any]) -> Bool {
          guard 1 < inActivityItems.count,
                inActivityItems[1] is EKEvent
          else { return false }
          
          return true
     }
     
     /* ################################################################## */
     /**
      This is the execution handler for the activity.
      */
     override func perform() {
          addReminderEvent()
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity {
     /* ################################################################## */
     /**
      This adds a reminder event for the next meeting start time.
      */
     func addReminderEvent() {
          /* ############################################################## */
          /**
           Completion proc for the permissions.
           
           - parameter inIsGranted: True, if permission was granted.
           - parameter inError: Any errors that occurred.
           */
          func calendarCompletion(_ inIsGranted: Bool, _ inError: Error?) {
               DispatchQueue.main.async { [weak self] in
                    guard nil == inError,
                          inIsGranted,
                          let self = self
                    else {
                         if !inIsGranted {
                              self?.displayPermissionsAlert(header: "SLUG-CALENDAR-PERM-ALERT-HEADER".localizedVariant, body: "SLUG-CALENDAR-PERM-ALERT-BODY".localizedVariant)
                         }
                         return
                    }
                    
                    let eventController = EKEventEditViewController()
                    eventController.event = meetingEvent
                    eventController.eventStore = self.myController?.eventStore
                    eventController.editViewDelegate = self
                    if .pad == self.myController?.traitCollection.userInterfaceIdiom,
                       let size = self.myController?.view?.bounds.size {
                         eventController.modalPresentationStyle = .popover
                         eventController.preferredContentSize = CGSize(width: size.width, height: size.height / 2)
                         eventController.popoverPresentationController?.sourceView = myController?.navigationController?.navigationBar
                         eventController.popoverPresentationController?.permittedArrowDirections = [.up]
                    }
                    
                    self.myController?.present(eventController, animated: true, completion: nil)
               }
          }
          
          if #available(iOS 17.0, *) {
               myController?.eventStore.requestWriteOnlyAccessToEvents(completion: calendarCompletion)
          } else {
               myController?.eventStore.requestAccess(to: EKEntityType.event, completion: calendarCompletion)
          }
     }
     
     /* ################################################################## */
     /**
      This displays an alert, for when permission is denied, and allows access to the settings.
      This can be called from non-main threads.
      
      - parameter header: The header. This can be a lo9calization slug.
      - parameter body: The message body. This can be a localization slug.
      */
     func displayPermissionsAlert(header inHeader: String, body inBody: String) {
          DispatchQueue.main.async {
               let style: UIAlertController.Style = .alert
               let alertController = UIAlertController(title: inHeader.localizedVariant, message: inBody.localizedVariant, preferredStyle: style)
               
               let okAction = UIAlertAction(title: "SLUG-CANCEL-BUTTON-TEXT".localizedVariant, style: .cancel, handler: nil)
               
               alertController.addAction(okAction)
               
               let settingsAction = UIAlertAction(title: "SETTINGS-ALERT-BUTTON-TEXT".localizedVariant, style: .default, handler: { _ in
                    VMF_AppDelegate.appDelegateInstance?.openMainSettings()
               })
               
               alertController.addAction(settingsAction)
               
               self.myController?.present(alertController, animated: true, completion: nil)
          }
     }
}

/* ###################################################################################################################################### */
// MARK: EKEventEditViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity: EKEventEditViewDelegate {
     /* ################################################################## */
     /**
      Called when the event kit has completed with an action to add the reminder to the calendar.
      
      - parameter inController: The controller we're talking about.
      - parameter didCompleteWith: The even action that completed.
      */
     func eventEditViewController(_ inController: EKEventEditViewController, didCompleteWith inAction: EKEventEditViewAction) {
          inController.dismiss(animated: true, completion: nil)
     }
}

/* ###################################################################################################################################### */
// MARK: - Custom Open Location In Activity Class -
/* ###################################################################################################################################### */
/**
 We can present a custom activity, that allows the user to open a location, using an installed app.
 */
class VMF_OpenLocationIn_Activity: VMF_Base_Activity {
     /* ################################################################################################################################## */
     // MARK: Enum That Transparently Handles A Location App
     /* ################################################################################################################################## */
     /**
      This enum abstracts the particulars of having multiple apps that can deal with the location.
      */
     enum LocationHandlerApp {
          /* ############################################################## */
          /**
           The built-in Apple Maps app.
           
           - parameter location: The placemark for the location.
           - parameter name: The name of the meeting.
           */
          case appleMaps(location: CLPlacemark, name: String)
          
          /* ############################################################## */
          /**
           The Google Maps app.
           
           - parameter location: The placemark for the location.
           - parameter name: The name of the meeting.
           */
          case googleMaps(location: CLPlacemark, name: String)
          
          /* ############################################################## */
          /**
           The (Google) Waze app.
           
           - parameter location: The placemark for the location.
           - parameter name: The name of the meeting.
          */
          case waze(location: CLPlacemark, name: String)
          
          /* ############################################################## */
          /**
           This returns the Universal Links URL for each of the types of apps.
           */
          var appURL: URL? {
               var ret: String = ""
               
               switch self {
               case let .appleMaps(inLocation, name):
                    if let coords = inLocation.location?.coordinate,
                       CLLocationCoordinate2DIsValid(coords) {
                         ret = "http://maps.apple.com/?ll=\(coords.latitude),\(coords.longitude)&q=\(name)"
                    }
                    
               case let .googleMaps(inLocation, _):
                    if let coords = inLocation.location?.coordinate,
                       let testURL = URL(string: "comgooglemaps://"),
                       UIApplication.shared.canOpenURL(testURL),
                       CLLocationCoordinate2DIsValid(coords) {
                         ret = "https://www.google.com/maps/search/?api=1&query=\(coords.latitude)%2C\(coords.longitude)"
                    }
                    
               case let .waze(inLocation, _):
                    if let coords = inLocation.location?.coordinate,
                       let testURL = URL(string: "waze://"),
                       UIApplication.shared.canOpenURL(testURL),
                       CLLocationCoordinate2DIsValid(coords) {
                         ret = "https://waze.com/ul?ll=\(coords.latitude),\(coords.longitude)&navigate=yes"
                    }
               }
               
               if let url = URL(string: ret),
                  UIApplication.shared.canOpenURL(url) {
                    return url
               }
               
               return nil
          }
          
          /* ############################################################## */
          /**
           This returns the App title.
           */
          var appTitle: String {
               var ret = "ERROR"
               
               switch self {
               case .appleMaps(_, _):
                    ret = "SLUG-APPLE-MAPS-APP-TITLE".localizedVariant
                    
               case .googleMaps(_, _):
                    ret = "SLUG-GOOGLE-MAPS-APP-TITLE".localizedVariant

               case .waze(_, _):
                    ret = "SLUG-WAZE-APP-TITLE".localizedVariant
               }
               
               return ret
          }
     }
     
     /* ################################################################## */
     /**
      This is the enum with the app, and the location (associated value).
      */
     let app: LocationHandlerApp

     /* ################################################################## */
     /**
      Default Initializer.
      - parameter app: The app enum case for this activity.
      - parameter myController: The controller that "owns" this activity.
      */
     init(app inApp: LocationHandlerApp, myController inMyController: VMF_MeetingInspectorViewController?) {
          app = inApp
          super.init(myController: inMyController)
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_OpenLocationIn_Activity {
     /* ################################################################## */
     /**
      The title string for this activity.
      */
     override var activityTitle: String? { String(format: "SLUG-OPEN-IN-FORMAT".localizedVariant, app.appTitle) }
     
     /* ################################################################## */
     /**
      The template image for the activity line.
      */
     override var activityImage: UIImage? { UIImage(systemName: "map") }
     
     /* ################################################################## */
     /**
      We have our own custom activity type.
      */
     override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("com.littlegreenviper.vmf.openIn-\(app.appTitle)") }
     
     /* ################################################################## */
     /**
      - parameter withActivityItems: The activity items (ignored).
      We return true, if the app is installed.
      */
     override func canPerform(withActivityItems: [Any]) -> Bool { nil != app.appURL }
     
     /* ################################################################## */
     /**
      This is the execution handler for the activity.
      */
     override func perform() {
          guard let appURL = app.appURL else { return }
          UIApplication.shared.open(appURL)
     }
}
