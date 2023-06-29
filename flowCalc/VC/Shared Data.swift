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
    
    static let post = Recipy()
    var body: Double?
    var aciduty: Double?
    var sweetness: Double?
    var bitterness: Double?
    var rating: Double?

    private init() { }
}
