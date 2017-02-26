//
//  ViewController.swift
//  test-thnets
//
//  Created by Eugenio Culurciello on 2/25/17.
//  Copyright © 2017 Eugenio Culurciello. All rights reserved.
//

import UIKit

import AVFoundation

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}


//class ViewController: UIViewController {
//    
//    // MARK: Properties:
//    @IBOutlet weak var label: UILabel!
//    @IBOutlet weak var button: UIButton!
//    @IBOutlet weak var imview: UIImageView!
//    var newMedia: Bool?
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    
//    // MARK: Actions:
//
//    @IBAction func buttonpressed(_ sender: Any) {
//        
//        // RUN THNETS TEST HERE:
//        
//        // access to neural-nets directory: http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
//        // let filemgr = FileManager.default
//        // let currentPath = filemgr.currentDirectoryPath
//        
//        // neural network variable:
//        var net: UnsafeMutablePointer<THNETWORK>
//
//        THInit();
//
//        // load neural net from project:
//        let docsPath = Bundle.main.resourcePath! + "/neural-nets/"
//        
//        //test if correct file located
//        let fileManager = FileManager.default
//        do {
//            let docsArray = try fileManager.contentsOfDirectory(atPath: docsPath)
//            print(docsArray)
//        } catch {
//            print(error)
//        }
//        
//        //Load Network
//        net = THLoadNetwork(docsPath)
//        print(net)
//
//        // run neural net:
////        if net == nil {
//            THUseSpatialConvolutionMM(net, 2);
//            
//            label.text = "Success!"
//            
////        } else {
////            label.text = "CRAPPED OUT!"
////        }
//        
//    }
//
//
//}

