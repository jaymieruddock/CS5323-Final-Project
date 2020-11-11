//
//  ViewController.swift
//  ML_Lab5
//
//  Created by Jaymie Ruddock on 11/11/20.
//

//
//  ViewController.swift
//  ARSMUExample
//
//  Created by Eric Larson on 11/2/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

let SERVER_URL = "http://10.8.2.126:8000"

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, URLSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    
    @IBOutlet weak var handleButton: UIButton!
    
    @IBOutlet weak var detectorTypeSwitch: UISwitch!
    
    @IBOutlet weak var detectorTypeLabel: UILabel!
    
    
    
    @IBAction func switchChanged(_ sender: Any) {
        if(detectorTypeSwitch.isOn){
            detectorTypeLabel.text = "Hand"
        }
        else{
            detectorTypeLabel.text = "Not Hand"
        }
    }
    
    
    lazy var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        return URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
    }()
    
    let operationQueue = OperationQueue()
    var ringBuffer = RingBuffer()
    var dsid:Int = 1
    
    //MARK: Class Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detectorTypeLabel.text = "Hand"
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
    }
    
    func random(_ n:Int) -> Int
    {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    
    
    
    @IBAction func handleButtonClicked(_ sender: Any) {
        /*TODO: Store the captured frame as a UIImage
                Add this image to an array (might not have to make array, just single image)
                Upload this array/image to the tornado server by using the sendFeatures() function
        */
        
        // grab the current AR session frame from the scene, if possible
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        // setup some geometry for a simple plane
        let imagePlane = SCNPlane(width:sceneView.bounds.width/6000,
                                  height:sceneView.bounds.height/6000)
        

        imagePlane.firstMaterial?.diffuse.contents = sceneView.snapshot()
        imagePlane.firstMaterial?.lightingModel = .constant
        
        // add the node to the scene
        let planeNode = SCNNode(geometry:imagePlane)
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        // update the node to be a bit in front of the camera inside the AR session
        
        // step one create a translation transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.1
        
        // step two, apply translation relative to camera for the node
        planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation )
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    


    
    // MARK: - Communicate with Server
    
    func sendFeatures(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array,
                                       "label":"hand",
                                       "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }

        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{
                        (data, response, error) in
                        if(error != nil){
                            if let res = response{
                                print("Response:\n",res)
                            }
                        }
                        else{ // no error we are aware of
                            let jsonDictionary = self.convertDataToDictionary(with: data)
                            
                            let labelResponse = jsonDictionary["prediction"]!
                            print(labelResponse)
                            self.displayLabelResponse(labelResponse as! String)

                        }
                                                                    
        })
        
        postTask.resume() // start the task
        
    }
    
    func displayLabelResponse(_ response:String){
        print("Response From Model Prediction: ", response)
    }
    
    
    
    
    
    
    // MARK: - JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            
            if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                            print("printing JSON received as string: "+strData)
            }else{
                print("json error: \(error.localizedDescription)")
            }
            return NSDictionary() // just return empty
        }
    }
    
    
}



    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
