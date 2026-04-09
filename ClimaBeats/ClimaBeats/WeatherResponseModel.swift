//
//  WeatherData.swift
//  ClimaBeats
//
//

import Foundation

struct WeatherData:Codable
{
    let location:LocationData
    let current:CurrentData
}
