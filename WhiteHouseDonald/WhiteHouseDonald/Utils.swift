//
//  Utils.swift
//  WhiteHouseDonald
//
//  Created by Zach Zeleznick on 10/16/16.
//  Copyright © 2016 zzeleznick. All rights reserved.
//

import Foundation
import GameKit

func RandomInt(min: Int, max: Int) -> Int {
    if max < min { return min }
    return Int(arc4random_uniform(UInt32((max - min) + 1))) + min
}

func RandomFloat() -> Float {
    return Float(arc4random()) /  Float(UInt32.max)
}

func RandomFloat(min: Float, max: Float) -> Float {
    return (Float(arc4random()) / Float(UInt32.max)) * (max - min) + min
}

func RandomDouble(min: Double, max: Double) -> Double {
    return (Double(arc4random()) / Double(UInt32.max)) * (max - min) + min
}

func RandomCGFloat() -> CGFloat {
    return CGFloat(RandomFloat())
}

func RandomCGFloat(min: Float, max: Float) -> CGFloat {
    return CGFloat(RandomFloat(min: min, max: max))
}

class RandomGenerator {
    var xGen: AnyObject!
    var yGen: AnyObject!

    init() {
        self.xGen = nil
        self.yGen = nil
        if #available(iOS 9.0, *) {
            let source = GKRandomSource()
            self.xGen = GKGaussianDistribution(randomSource: source,
                                           lowestValue: 3, highestValue: 12)
            self.yGen = GKGaussianDistribution(randomSource: source,
                                               lowestValue: 12, highestValue: 24)
        } else {
            // Fallback on earlier versions
        }
    }
    func getX() -> Int {
        if #available(iOS 9.0, *) {
            return self.xGen.nextInt()
        }
        return RandomInt(min: 3, max: 12)
    }
    func getY() -> Int {
        if #available(iOS 9.0, *) {
             return self.yGen.nextInt()
        }
        return RandomInt(min: 12, max: 24)
    }
}


