//
//  ViewController.swift
//
//  Created by Jaymie Ruddock on 10/10/20.
//

import UIKit

let Motion = CoreMotionManager()

class MainViewController: UIViewController, UITextFieldDelegate {


    @IBOutlet weak var ProgressBar: ProgressBar!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var toGoal: UILabel!
    
//
//    @IBOutlet weak var userGoal: UITextField!
//    @IBOutlet weak var canPlay: UIButton!
//    @IBOutlet weak var toGoal: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Motion.startUpdates()
        // Do any additional setup after loading the view.
        activityLabel.text = Motion.activity_label
        stepsLabel.text = Motion.steps_today

        ProgressBar.trackColor = UIColor.lightGray
        ProgressBar.progressColor = UIColor.red
        ProgressBar.setProgressWithAnimation(duration: 1.0, value: 0.0)
        
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.updateStepsAndActivity), userInfo: nil, repeats: false)
        
        Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(self.updateStepsAndActivity), userInfo: nil, repeats: true)
    }
    
//    func readPrevGoal() {
//        if let path = Bundle.main.path(forResource: "Goal", ofType: "txt") {
//            do {
//                let data = try String(contentsOfFile: path, encoding: .utf8)
//                let myStrings = data.components(separatedBy: .newlines)
//                userGoal.text = myStrings[-1]
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func updateGoal(newGoal:String) {
//        let fileName = "Goal"
//        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
//        let writeString = userGoal.text
//                do {
//                    // Write to the file
//                    try writeString?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
//                } catch let error as NSError {
//                    print("Failed writing to file")
//                }
//
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        updateStepsAndActivity()
//        updateGoal(newGoal: userGoal.text ?? "1")
//        textField.resignFirstResponder()
//    }

    //refreshes the information
    @IBAction func refreshInfo(_ sender: UIBarButtonItem) {
        updateStepsAndActivity()
    }
    
    //gets the initial values, there is a lag
    //due to the queue so it must wait
    @objc
    func updateStepsAndActivity() {
        activityLabel.text = Motion.activity_label
        stepsLabel.text = Motion.steps_today
        let prog = Double(stepsLabel.text ?? "0") ?? 0
        var goal = 10000
        var goal_int = prog/Double(goal) ?? 0.0
        ProgressBar.setProgressWithAnimation(duration: 1.0, value: Float(goal_int))
        var difference = Int(Double(goal)-prog)
        
        
        if goal_int >= 1.0 {
            toGoal.text = "Congrats! Goal Reached!"
            Motion.setPlay(willPlay: true)
        }
        else {
            toGoal.text = "\(difference) steps to goal"
            Motion.setPlay(willPlay: false)
        }
    }

}



