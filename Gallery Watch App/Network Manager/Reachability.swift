//
//  Reachability.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 25/01/23.
//

import Foundation
import WatchConnectivity
class Reachability {
    static func isConnectedToNetwork() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            return session.isReachable
        } else {
    return false
   }
 }
}
