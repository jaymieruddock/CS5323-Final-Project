//
//  CoreMotionManager.swift
//  CoreMotion_Lab3
//
//  Created by Jaymie Ruddock on 10/12/20.
//

import Foundation
import CoreMotion

class CoreMotionManager {
    
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var canPlay:Bool = false
    var activity_label: String = ""
    var steps_label: String = ""
    var steps_today: String = ""
    var steps_yesterday: String = ""
    
    //tracks the activity
    func startTrackingActivity() {
        activityManager.startActivityUpdates(to: OperationQueue.main) {
            [weak self] (activity: CMMotionActivity?) in
            
            guard let activity = activity else { return }
            DispatchQueue.main.async {
                if activity.walking {
                    self?.activity_label = "Walking"
                }
                else if activity.stationary {
                    self?.activity_label = "Stationary"
                }
                else if activity.automotive {
                    self?.activity_label = "Automotive"
                }
                else if activity.running {
                    self?.activity_label = "Running"
                }
                else {
                    self?.activity_label = "Unknown"
                }
            }
        }
    }
    
    //gets yesterdays step count
    func getYesterdaysData() {
        if(CMPedometer.isStepCountingAvailable()) {
            DispatchQueue.main.async {
                let C = Calendar.current
                let startDay = C.startOfDay(for: Date())
                let yesterday = C.date(byAdding: .day, value: -1, to: startDay)
                self.pedometer.queryPedometerData(from: yesterday!, to: startDay) { (data : CMPedometerData!, error) -> Void in
                    if(error == nil){
                        self.steps_yesterday = data.numberOfSteps.stringValue
                        print("steps yesterday: ", self.steps_yesterday)
                    }
                }
            }
        }
    }
    
    //gets todays step count so far
    func getTodaysData() {
        if(CMPedometer.isStepCountingAvailable()) {
            DispatchQueue.main.async {
                let C = Calendar.current
                let startDay = C.startOfDay(for: Date())
                //let today = C.date(byAdding: .day, value: -1, to: Date())
                self.pedometer.queryPedometerData(from: startDay, to: Date()) { (data : CMPedometerData!, error) -> Void in
                    if(error == nil){
                        self.steps_today = data.numberOfSteps.stringValue
                        print("steps today: ", self.steps_today)
                    }
                }
            }
        }
    }
    
    //determines whether user can play game
    func setPlay(willPlay:Bool) {
        self.canPlay = willPlay
    }
    
    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
            [weak self] pedometer, error in
            guard let pedometer = pedometer, error == nil else { return }
            DispatchQueue.main.async {
                //self?.steps_label = pedometer.numberOfSteps.stringValue
            }
        }
    }
    
    func startUpdates() {
        if CMMotionActivityManager.isActivityAvailable() {
            startTrackingActivity()
        }
        
        if CMPedometer.isStepCountingAvailable() {
            startCountingSteps()
            getYesterdaysData()
            getTodaysData()
        }
    }
    
    
    
    
}
