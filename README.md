# LEOFindIt_iOS -- Detect Hidden BTLE Tracking Devices

## Overview

LEOFindIt_iOS is a hybrid mobile application developed using Flutter and native iOS technologies to detect and classify Bluetooth Low Energy (BLE) tracking devices such as:
 - Apple AirTags
 - Samsung SmartTags
 - Tile trackers
 - Unknown BLE devices

Technology is increasingly used to monitor individuals without consent, thus we developed this application to address these real-world concerns related to cyberstalking and unauthorized tracking.

Studies show that 80% of stalking victims are tracked using technology, and millions are affected annually (https://www.safehome.org/data/cyberstalking-statistics/).

By leveraging BLE advertisement scanning and device classification techniques, this project provides real-time detection and situational awareness for both civilians and law enforcement personnel.
 
## Objectives
 - Detect nearby BLE tracking devices using passive scanning
 - Classify devices based on manufacturer and protocol patterns
 - Estimate proximity using RSSI signal modeling
 - Provide actionable insights to users in real time
 - Support privacy-preserving and offline functionality

## Architecture
The application utilizes a hybrid architecture combining Flutter (UI layer) and native iOS Bluetooth capabilities.

Flutter UI Layer -> MethodChannel Bridge -> Native Swift Layer (CoreBluetooth) -> BLE Advertisement Processing -> Device Classification & Distance Estimation

## Features
 - Real-time BLE scanning
 - Cross-brand tracker detection (Apple, Samsung, Tile)
 - RSSI-based distance estimation
 - Device classification and labeling
 - Filtering and sorting of detected devices
 - Historical tracking of detected signals

## Technology Stack
UI - Flutter (Dart)
Native - Swift
BLE Framwork - CoreBluetooth
Communication - MethodChannel
Tools - Xcode, VS Code, GitHub

## Requirements

 - iOS 13 or higher
 - Xcode 12+
 - Swift 5+
 - CocoaPods 1.10+

## Installation

git clone https://github.com/yourusername/LEOFindIt_iOS.git<br>
cd LEOFindIt_iOS<br>
flutter clean<br>
flutter pub get<br>
cd ios<br>
pod install<br>
cd ..

Restart Xcode after cd ..<br>
Open ios/Runner.xcworkspace

## Running the App

1. Open Runner.xcworkspace
2. Select device or simulator
3. Press Run
