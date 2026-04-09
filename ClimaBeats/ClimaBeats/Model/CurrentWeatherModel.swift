//
//  CurrentData.swift
//  ClimaBeats
//
//

import Foundation

struct CurrentData:Codable
{
    let last_updated:String
    let temp_c:Float
    let wind_kph:Float
    let humidity:Int
    let condition:Condition
}
