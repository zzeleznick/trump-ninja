//
//  GameViewController.swift
//  WhiteHouseDonald
//
//  Created by Zach Zeleznick on 10/16/16.
//  Copyright © 2016 zzeleznick. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(view.frame.size)
        let w = view.frame.size.width
        let h = view.frame.size.height
        self.view = SKView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            let scene = GameScene(size: CGSize(width: 1334, height: 750))
            // iPhone -> (667.0, 375.0)
            print("Cast Success")
            let model = UIDevice.current.model
            print(model)
            switch model {
            case "iPad":
                print("iPad detected")
                // iPad -> (480.0, 320.0)
                scene.size = CGSize(width: 480, height: 320)
                scene.iPad = true
                // scene.size = CGSize(width: 2048, height: 1536)
            default:
                break
            }
            // if let scene = SKScene(fileNamed: "GameScene") {

            scene.scaleMode = .resizeFill
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
