//
//  Shared Data.swift
//  flowCalc
//
//  Created by reinert wasserman on 29/6/2023.
//

class Recipy {
    static let pre = Recipy()

    var dose        : Double?
    var grindSize   : Double?
    var rpm         : Double?
    var preWet      : Bool?

    private init() { }
}
