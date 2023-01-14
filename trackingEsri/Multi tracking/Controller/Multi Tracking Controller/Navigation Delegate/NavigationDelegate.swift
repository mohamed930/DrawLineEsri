//
//  NavigationDelegate.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 13/01/2023.
//

import Foundation
import ArcGIS

extension TrackCarViewController: AGSRouteTrackerDelegate {
   func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
       Navi.updateTrackingStatusDisplay(routeTracker: routeTracker, status: trackingStatus)
   }
       
   func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
       setSpeakDirection(with: voiceGuidance.text)
   }

   func setSpeakDirection(with text: String) {
       speechSynthesizer.stopSpeaking(at: .immediate)
       speechSynthesizer.speak(AVSpeechUtterance(string: text))
   }
}

extension TrackCarViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        Navi.hadnleLocationChange(location: location)
    }
}
