//
//  ViewController.swift
//  CameraExample
//
//  https://www.invasivecode.com/weblog/AVFoundation-Swift-capture-video/?doing_wp_cron=1488224967.7605888843536376953125
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

	override func viewDidLoad() {
		super.viewDidLoad()
		setupCameraSession()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		view.layer.addSublayer(previewLayer)

		cameraSession.startRunning()
	}
    
    // THNETS neural network loading and initalization:
    var net: UnsafeMutablePointer<THNETWORK>?
    // load neural net from project:
    let docsPath = Bundle.main.resourcePath! + "/neural-nets/"

	lazy var cameraSession: AVCaptureSession = {
		let s = AVCaptureSession()
		s.sessionPreset = AVCaptureSessionPresetMedium //https://developer.apple.com/reference/avfoundation/avcapturesession/video_input_presets
        return s
	}()

	lazy var previewLayer: AVCaptureVideoPreviewLayer = {
		let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
		preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
		preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
		preview?.videoGravity = AVLayerVideoGravityResize
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
        
        // THNETS:
        // Load Network
        net = THLoadNetwork(docsPath)
        print(net)
        
        // setup neural net:
        if net != nil { THUseSpatialConvolutionMM(net, 2) }
	}

	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		// Here you collect each frame and process it
        let methodStart = NSDate()
        
        //http://stackoverflow.com/questions/8493583/ios-scale-and-crop-cmsamplebufferref-cvimagebufferref
        //let cropX0, cropY0, cropHeight=224, cropWidth=224, outWidth, outHeight: Int
        
//        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//        
//        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
//        let width = CVPixelBufferGetWidth(imageBuffer)
//        let height = CVPixelBufferGetHeight(imageBuffer)
//        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer)
//    
//        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0));
//        
//        print("width, height:")
//        print(width)
//        print(height)
//        print("bytes per row:")
//        print(bytesPerRow)
        
        
        // THNETS process image:
        let nbatch:Int32 = 1
        let width:Int32 = 256
        let height:Int32 = 256
        var image = [Float](repeating: 0.0, count: 3*256*256) // contains pixel data
        var results: UnsafeMutablePointer<Float>?
        var outwidth: CInt = 0
        var outheight: CInt = 0
        THProcessFloat(net, &image, nbatch, width, height, &results, &outwidth, &outheight);

        
        // print time:
        let methodFinish = NSDate()
        let executionTime = methodFinish.timeIntervalSince(methodStart as Date)
        print("Execution time: \(executionTime)")
	}
    

	func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		// Here you can count how many frames are dopped
	}
	
    
}

