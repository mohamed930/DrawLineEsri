//
//  BackgroundThread.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 24/12/2022.
//

import Foundation

extension DispatchQueue {

    /*static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }*/
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
            background?()
            
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

}
