//
//  MapperHelper.swift
//  PoseFinder
//
//  Created by iOS Dev on 17/12/25.
//  Copyright © 2025 Apple. All rights reserved.
//


final class MapperHelper {

    // MARK: - Common Mapper

    private static func map(
        value: Int,
        inMin: Int,
        inMax: Int,
        outMin: Int,
        outMax: Int,
        clamp: Bool = true
    ) -> Int {

        let input: Int
        if clamp {
            input = max(min(inMin, inMax), min(max(inMin, inMax), value))
        } else {
            input = value
        }

        return outMin +
            (input - inMin) * (outMax - outMin) / (inMax - inMin)
    }
    //y-z plane mapper
    static func mapLeftShoulderYZ(_ degree: Int) -> Int {
        map(value: degree,
            inMin: -90,
            inMax: 180,
            outMin: 4095,
            outMax: 1)
    }
    static func mapLeftSolder(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 0,
            inMax: 180,
            outMin: 3600,
            outMax: 500
        )
    }

    static func mapRightSolder(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 180,
            inMax: 360,
            outMin: 3500,
            outMax: 500
        )
    }

    static func mapLeftElbow(_ degree: Int) -> Int {
        map(value: degree,
            inMin: -90,
            inMax: 90,
            outMin: 3600,
            outMax: 500
        )
    }

    static func mapRightElbow(_ degree: Int) -> Int {
        map(value: degree,
            inMin: -90,
            inMax: 90,
            outMin: 3600,
            outMax: 500
        )
    }

    //movement till 45 degree only...
    static func mapRightHip(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 0,
            inMax: -45,
            outMin: 1500,
            outMax: 500,
        )
    }
    //movement till 45 degree only...
    static func mapLeftHip(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 0,
            inMax: 45,
            outMin: 1600,
            outMax: 2550,
        )
    }
    
    static func mapBackCameraLeftSholder(_ degree: Int) -> Int {
        let convertedDegree = map(
            value: degree,
            inMin: 360,
            inMax: 180,
            outMin: 0,
            outMax: 180
        )
        return mapLeftSolder(convertedDegree)
    }
    
    static func mapBackCameraRightSholder(_ degree: Int) -> Int {
        let convertedDegree = map(
            value: degree,
            inMin: 0,
            inMax: 180,
            outMin: 360,
            outMax: 180
        )
        return mapRightSolder(convertedDegree)
    }
    static func mapBackCameraLeftElbow(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 90,
            inMax: -90,
            outMin: 3600,
            outMax: 500)
    }
    static func mapBackCameraRightElbow(_ degree: Int) -> Int {
        map(value: degree,
            inMin: 90,
            inMax: -90,
            outMin: 3600,
            outMax: 500)
    }
    static func mapBackCameraLeftHip(_ degree: Int) -> Int {
        let convertedDegree = map(
            value: degree,
            inMin: 0,
            inMax: -45,
            outMin: 0, outMax: 45,
        )
        return mapLeftHip(convertedDegree)
    }
    
    static func mapBackCameraRightHip(_ degree: Int) -> Int {
        let convertedDegree = map(
            value: degree,
            inMin: 0,
            inMax: 45,
            outMin: 0, outMax: -45,
        )
        return mapRightHip(convertedDegree)
    }
}
