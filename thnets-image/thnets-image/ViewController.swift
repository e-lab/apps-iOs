//
//  ViewController.swift
//  CameraExample
//
//  https://www.invasivecode.com/weblog/AVFoundation-Swift-capture-video/?doing_wp_cron=1488224967.7605888843536376953125
//

import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var camView: UIView!
    @IBOutlet weak var textresults: UILabel!
    @IBOutlet weak var textfps: UILabel!
    @IBOutlet weak var imageview: UIImageView!
    
	override func viewDidLoad() {
		super.viewDidLoad()
		runOnImage()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		camView.addSubview(textresults)
        camView.addSubview(textfps)

	}
    
    
    // THNETS neural network loading and initalization:
    let nnEyeSize = 128
    var categories:[String] = []
    var net: UnsafeMutablePointer<THNETWORK>?
    // load neural net from project:
    let docsPath = Bundle.main.resourcePath! + "/neural-nets/"


    
    func convert<T>(count: Int, data: UnsafePointer<T>) -> [T] {
        
        let buffer = UnsafeBufferPointer(start: data, count: count);
        return Array(buffer)
    }
    
    func runOnImage(){
        
        // THNETS init and load
        THInit();
        
        //test if correct file located
        let fileManager = FileManager.default
        do {
            let docsArray = try fileManager.contentsOfDirectory(atPath: docsPath)
            print(docsArray)
        } catch {
            print(error)
        }
        
        // load categories file:
        if true {
            do {
                let data = try String(contentsOfFile: "\(docsPath)/categories.txt", encoding: .utf8)
                categories = data.components(separatedBy: .newlines)
                categories.remove(at: 0)
                categories.remove(at: 46)
                //print(categories)
            } catch {
                print(error)
            }
        }
        
        
        // Load Network
        net = THLoadNetwork(docsPath)
        //print(net)
        
        // setup neural net:
        if net != nil { THUseSpatialConvolutionMM(net, 2) }
        
        // Here you collect each frame and process it
        let methodStart = NSDate()
        
        
        // test with images: THIS WORKS!
        let testImage = UIImage(named: "face") // or "hand" or "face"
        imageview.image = testImage //display the test image on screen
        print("testImage size:", testImage!.size)
        print(testImage?.cgImage!.colorSpace) // gives: <CGColorSpace 0x170035420> (kCGColorSpaceICCBased; kCGColorSpaceModelRGB; sRGB IEC61966-2.1)
        let pixelData = testImage?.cgImage!.dataProvider!.data
        
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) // data is in BGRA format
        
        // convert image data to array for test:
        let imdatay = convert(count:16, data: data)
        print("input image:", imdatay)
        
        /// convert BGRA to RGB:
        var idx = 0
        var dataRGB = [CUnsignedChar](repeating: 0, count: (nnEyeSize*nnEyeSize*3))
        for i in stride(from:0, through: nnEyeSize*nnEyeSize*4-1, by: 4) { // every 4 values do this:
            dataRGB[idx]   = data[i+2]
            dataRGB[idx+1] = data[i+1]
            dataRGB[idx+2] = data[i]
            idx = idx+3
        }
        
        // get usable pointer to image:
        var pimage : UnsafeMutablePointer? = UnsafeMutablePointer(mutating: dataRGB)
        
        // convert image data to array for test:
        let imdatay2 = convert(count:16, data: pimage!)
        print("converted image:", imdatay2)
        
        // THNETS process image:
        let nbatch: Int32 = 1
        //var data = [UInt8](repeating: 0, count: 3*nnEyeSize*nnEyeSize) // TEST pixel data
        //var pimage: UnsafeMutablePointer? = UnsafeMutablePointer(mutating: data) // TEST pointer to pixel data
        var results: UnsafeMutablePointer<Float>?
        var outwidth: Int32 = 0
        var outheight: Int32 = 0
        THProcessImages(net, &pimage, nbatch, Int32(nnEyeSize), Int32(nnEyeSize), Int32(3*nnEyeSize), &results, &outwidth, &outheight, Int32(0));
        print("TH out sizes:", outwidth, outheight)
        
        // convert results to array:
        let resultsArray = convert(count:categories.count, data: results!)
        //print("Detections:", resultsArray)
        //for i in 0...45 {
        //    print(i, categories[i], resultsArray[i])
        //}
        let sorted = resultsArray.enumerated().sorted(by: {$0.element > $1.element})
        // print them to console:
        var stringResults:String = ""
        for i in 0...4 {
            print(sorted[i], categories[sorted[i].0])
            stringResults.append("\(categories[sorted[i].0]) \(sorted[i].1) \n")
        }
        // in order to display it in the main view, we need to dispatch it to the main view controller:
        DispatchQueue.main.async { self.textresults.text = stringResults }
        
        // print time:
        let methodFinish = NSDate()
        let executionTime = methodFinish.timeIntervalSince(methodStart as Date)
        print("Processing time: \(executionTime) \n")
        DispatchQueue.main.async { self.textfps.text = "FPS: \(1/executionTime)" }
    
    }



}

