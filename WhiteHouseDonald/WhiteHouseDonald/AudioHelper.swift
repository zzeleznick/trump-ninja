//
//  AudioHelper.swift
//  WhiteHouseDonald
//
//  Created by Zach Zeleznick on 10/16/16.
//  Copyright © 2016 zzeleznick. All rights reserved.
//

import Foundation

let TrumpPhrases = ["really_rich", "run_win", "great_again", "wall", "beat_china"]
let TrumpLoserNoises = ["fired", "trump_wrong"]
let TrumpVictorNoises = ["fantastic", "congratulations", "watching", "big_china"]

func getRandomPhrase() -> String {
    let idx = RandomInt(min: 0, max: TrumpPhrases.count - 1)
    return TrumpPhrases[idx]
}

func getRandomSound() -> String {
    let idx = RandomInt(min: 0, max: TrumpVictorNoises.count - 1)
    return TrumpVictorNoises[idx]
}
