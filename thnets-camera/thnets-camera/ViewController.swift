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
    
	override func viewDidLoad() {
		super.viewDidLoad()
		setupCameraSession()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		camView.layer.addSublayer(previewLayer)
        camView.addSubview(textresults)
        camView.addSubview(textfps)

		cameraSession.startRunning()
	}
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        
        layer.videoOrientation = orientation
        
        previewLayer.frame = self.view.bounds
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /*
        if let connection =  self.previewLayer.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                    break
                }
            }
        }*/
    }

    
    // THNETS neural network loading and initalization:
    let nnEyeSize = 128
    var categories:[String] = []
    var net: UnsafeMutablePointer<THNETWORK>?
    // load neural net from project:
    let docsPath = Bundle.main.resourcePath! + "/neural-nets/"

	lazy var cameraSession: AVCaptureSession = {
		let captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSessionPresetMedium //https://developer.apple.com/reference/avfoundation/avcapturesession/video_input_presets
        return captureSession
	}()

	lazy var previewLayer: AVCaptureVideoPreviewLayer = {
		let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
		preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
		preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
		//preview?.videoGravity = AVLayerVideoGravityResize
		return preview!
	}()

	func setupCameraSession() {
		let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice

		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
			
			cameraSession.beginConfiguration()

			if (cameraSession.canAddInput(deviceInput) == true) {
				cameraSession.addInput(deviceInput)
			}

			let dataOutput = AVCaptureVideoDataOutput()
			dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)] //https://developer.apple.com/reference/corevideo/cvpixelformatdescription/1563591-pixel_format_types
			dataOutput.alwaysDiscardsLateVideoFrames = true

			if (cameraSession.canAddOutput(dataOutput) == true) {
				cameraSession.addOutput(dataOutput)
			}

			cameraSession.commitConfiguration()

			let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
			dataOutput.setSampleBufferDelegate(self, queue: queue)

		}
		catch let error as NSError {
			NSLog("\(error), \(error.localizedDescription)")
		}
        
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
	}
    
    func resizedCroppedImage(image: UIImage, newSize:CGSize) -> UIImage { //http://stackoverflow.com/questions/603907/uiimage-resize-then-crop
        var ratio: CGFloat = 0
        var delta: CGFloat = 0
        var offset = CGPoint.zero
        if image.size.width > image.size.height {
            ratio = newSize.width / image.size.width
            delta = (ratio * image.size.width) - (ratio * image.size.height)
            offset = CGPoint(x:delta/2, y:0)
        } else {
            ratio = newSize.width / image.size.height
            delta = (ratio * image.size.height) - (ratio * image.size.width)
            offset = CGPoint(x:0, y:delta/2)
        }
        let clipRect = CGRect(x:-offset.x, y:-offset.y, width:(ratio * image.size.width) + delta, height:(ratio * image.size.height) + delta)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        UIRectClip(clipRect)
        image.draw(in: clipRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func convert<T>(count: Int, data: UnsafePointer<T>) -> [T] {
        
        let buffer = UnsafeBufferPointer(start: data, count: count);
        return Array(buffer)
    }

	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		// Here you collect each frame and process it
        let methodStart = NSDate()
        
        // get pixel buffer:
        //http://stackoverflow.com/questions/8493583/ios-scale-and-crop-cmsamplebufferref-cvimagebufferref
        let cropWidth = nnEyeSize
        let cropHeight = nnEyeSize
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let cameraImage = CIImage(cvPixelBuffer: imageBuffer)
        let uiImage = UIImage(ciImage: cameraImage)
        print("Camera input size:", uiImage.size)
        
        // crop and scale buffer:
//        let croppedScaledImage = resizedCroppedImage(image: uiImage, newSize: CGSize(width:cropWidth, height:cropHeight))
//        print("croppedScaledImage size:", croppedScaledImage.size)
//        //print(croppedScaledImage.cgImage?.colorSpace) // gives: <CGColorSpace 0x174020d00> (kCGColorSpaceICCBased; kCGColorSpaceModelRGB; sRGB IEC61966-2.1)
//        let pixelData = croppedScaledImage.cgImage!.dataProvider!.data
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) // data is in BGRA format
//        //var pimage: UnsafeMutablePointer? = UnsafeMutablePointer(mutating: data)
//        
//        // convert image data to array for test:
//        let imdatay = convert(count:16, data: data)
//        print("input image:", imdatay)
//        
        
        // test with images:
        let testImage = UIImage(named: "face") // or "hand" or "face"
        print("testImage size:", testImage?.size)
        let pixelData = testImage?.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) // data is in BGRA format
//        var pimage: UnsafeMutablePointer? = UnsafeMutablePointer(mutating: data)
        
        /// convert BGRA to RGB:
        var idx = 0
        var dataRGB = [CUnsignedChar](repeating: 0, count: (nnEyeSize*nnEyeSize*3))
        for i in stride(from:0, through: nnEyeSize*nnEyeSize*4-1, by: 4) { // every 4 values do this:
            dataRGB[idx]   = data[i+2]
            dataRGB[idx+1] = data[i+1]
            dataRGB[idx+2] = data[i]
            idx = idx+3
        }
        
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
        THProcessImages(net, &pimage, nbatch, Int32(cropWidth), Int32(cropHeight), Int32(3*cropWidth), &results, &outwidth, &outheight, Int32(0));
        print("TH out sizes:", outwidth, outheight)
        
        // convert results to array:
        let resultsArray = convert(count:categories.count, data: results!)
        print("Detections:", resultsArray)
        for i in 0...45 {
            print(i, categories[i], resultsArray[i])
        }
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
        print("Execution time: \(executionTime) \n")
        DispatchQueue.main.async { self.textfps.text = "FPS: \(1/executionTime)" }
	}
    

	func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		// Here you can count how many frames are dropped
	}
    
    
}

