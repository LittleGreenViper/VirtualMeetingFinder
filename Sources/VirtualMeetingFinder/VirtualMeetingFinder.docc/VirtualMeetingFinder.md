# ``VirtualMeetingFinder`

An app that makes it simple to discover and attend virtual (and hybrid) NA meetings.

## Overview

![Icon](icon.png)

This app works by downloading a large list of virtual (and hybrid) meetings from a worldwide database, then presents them to the user, in a form that is directly useful to the user.

## Usage

This app connects to an instance of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and downloads the entire dataset for all meetings that have a virtual component (Either full virtual, or hybrid Virtual/in-Person). It either does this, when starting "cold," after 4 hours have passed, or at the user's behest (by doing a "pull-to refresh" on the table).

It then converts the meeting start and end times to the user's current timezone, and presents the meetings as a list, segregated by the weekday, and meeting start time. The user can use a couple of simple controls to select a day and start time for the meeting.

Each meeting can be inspected individually, in order to see things like formats, in-person addresses, and virtual URLs. Also, if the user has an app installed (for example, [Zoom](https://zoom.us)), and the meeting has a join URL, the app will translate it to that app's URL scheme, and open the app directly (without having to go through Safari).

Users can select a meeting as one they attend, which allows those meetings to be grouped into a separate screen.

## The Specifics

### The Screens

#### The Main Screen

The Main Screen presents a list of meetings, surmounted by a segmented switch that allows the user to select a weekday (or mode), and a bar that allows the user to select a time.

#### The Attendance Screen

If the user has selected one or more meetings as ones they attend, a bar button enables in the Main Screen, allowing the user to bring in another screen, with just the meetings they marked as ones they attend.

#### The Meeting Inspector Screen

If the user selects a single meeting from the list, another screen is brought in, that displays specific and detailed information about that meeting.

#### The Settings Screen

This is a screen that is brought in from the Main Screen, that allows the user to specify various settings.

### The About This App Screen

This is another scren that is brought in from the Settings Screen, that has information about the app, such as its specific version, and links to dependencies.

## Dependencies

- [`RVS_BasicGCDTimer`](https://github.com/RiftValleySoftware/RVS_BasicGCDTimer)

- [`RVS_Generic_Swift_Toolbox`](https://github.com/RiftValleySoftware/RVS_Generic_Swift_Toolbox)

- [`RVS_PersistentPrefs`](https://github.com/RiftValleySoftware/RVS_PersistentPrefs)

- [`RVS_UIKit_Toolbox`](https://github.com/RiftValleySoftware/RVS_UIKit_Toolbox)

- [`SwiftBMLSDK`](https://github.com/LittleGreenViper/SwiftBMLSDK)

- [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer)

- [The Basic Meeting List Toolbox (BMLT)](https://bmlt.app)

## Privacy

[The Privacy Policy](https://littlegreenviper.com/welcome-to-little-green-viper/privacy/app-privacy/)
