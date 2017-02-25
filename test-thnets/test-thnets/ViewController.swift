//
//  ViewController.swift
//  test-thnets
//
//  Created by Eugenio Culurciello on 2/25/17.
//  Copyright © 2017 Eugenio Culurciello. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Properties:
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Actions:

    @IBAction func buttonpressed(_ sender: Any) {

        // RUN THNETS TEST HERE:
        label.text = "Success!"
        
        // access to neural-nets directory: http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
//        let filemgr = FileManager.default
//        let currentPath = filemgr.currentDirectoryPath
        
        // neural network variable:
        var net: UnsafeMutablePointer<THNETWORK>

        THInit();

        // load neural net:
        net = THLoadNetwork("/Users/eugenioculurciello/Code/github/apps-iOs/test-thnets/neural-nets/");
        print(net)

        // run neural net:
//        if net == nil {
            THUseSpatialConvolutionMM(net, 2);
            
            label.text = "Success!"
            
//        } else {
//            label.text = "CRAPPED OUT!"
//        }
        
    }


}

