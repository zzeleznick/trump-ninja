//
//  ViewExtension.swift
//  WhiteHouseDonald
//
//  Created by Zach Zeleznick on 10/16/16.
//  Copyright © 2016 zzeleznick. All rights reserved.
//

import UIKit
import SpriteKit

func RandomColor() -> UIColor {
    return UIColor(red: RandomCGFloat(), green: RandomCGFloat(), blue: RandomCGFloat(), alpha: 1)
}

func fadeAway() -> SKAction  {
    let scaleOut = SKAction.scale(to: 0.001, duration:0.2)
    let fadeOut = SKAction.fadeOut(withDuration: 0.2)
    let group = SKAction.group([scaleOut, fadeOut])
    return SKAction.sequence([group, SKAction.removeFromParent()])
}



/*
 
 High scores
 Wave Labels
 Background music 
    - sound toggle
 Score multiplier
 Special Pepe / glowing trump
 Soundbites
    - wall 
    - huge
    - china
 */
