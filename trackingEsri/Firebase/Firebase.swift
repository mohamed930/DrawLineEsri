//
//  Firebase.swift
//  MultiTracking
//
//  Created by Mohamed Ali on 26/11/2022.
//

import Foundation
import FirebaseCore
import FirebaseDatabase

class Firebase {
    
    private var ref:DatabaseReference?
    
    
    func SetRefernce(ref: DatabaseReference) {
        self.ref = ref
    }
    
     func observeDataWithListner(event: DataEventType = .value, completion: @escaping (DataSnapshot) -> Void) {
         
         ref?.observe(event, with: completion)
     }
    
    func observerDataWithoutListner(completion: @escaping (DataSnapshot) -> Void) {
        ref?.getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
          completion(snapshot)
        });
    }
    
    func observeDataWithoutListnerWithCondition(k:String,v:String,completion: @escaping (DataSnapshot) -> Void) {
        
        ref?.queryOrdered(byChild: k).queryEqual(toValue: v).observeSingleEvent(of: .value, with: { snapshot in
            completion(snapshot)
        })
        
//        ref?.queryOrdered(byChild: k).queryEqual(toValue: v).getData(completion:  { error, snapshot in
//          guard error == nil else {
//            print(error!.localizedDescription)
//            return;
//          }
//          completion(snapshot)
//        });
    }
    
    // MARK: TODO:- This Method for Write data to dicrect child
    // ---------------------------------------------------------
    public func write(value:[String:Any],complention: @escaping () -> ()) {
        ref?.setValue(value){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                complention()
            }
        }
    }
    // ---------------------------------------------------------
}
