//
//  GeoMLModel.swift
//  WhereAmI
//
//  Created by exey on 24.06.2024.
//

import Vision
import CoreML
import CoreLocation
import UIKit

extension Double {
    func rounded(digits: Int) -> String {
        let multiplier = pow(10.0, Double(digits))
        return "\((self * multiplier).rounded() / multiplier)"
    }
}

struct ImageData: Identifiable {
    let name: String
    var label: String = ""
    let id: UUID = .init()
}

final class GeoMLModel: ObservableObject {
    
    @Published var images = [
        ImageData(name: "hand"),
        ImageData(name: "kremlin"),
        ImageData(name: "pantheon"),
        ImageData(name: "london"),
        ImageData(name: "louvre"),
        ImageData(name: "trevifountain"),
        ImageData(name: "eiffeltower"),
        ImageData(name: "sk8er"),
        ImageData(name: "sashka"),
    ]
    
    func detect() {
        guard let model = try? VNCoreMLModel(for: RN1015k500().model) else {
            print("NO MODEL")
            return
        }
        
        for i in 0..<images.count {
            guard let image = UIImage(named: images[i].name) else {
                print("NO Image")
                return
            }
            
            let request = VNCoreMLRequest(model: model) { response, error in
                
                if let observations = response.results as? [VNClassificationObservation] {
                    
                    var topPlaces = observations.prefix(5).map { ($0.identifier, $0.confidence) }
                    var topPlacesString:Array<(Double, String)> = .init()
                    
                    for j in 0..<topPlaces.count {
                        let place = topPlaces[j]
                        let split = place.0.split(separator: "\t")
                        let chance: Double = Double(place.1)*100
                        let (lat, lon) = (Double(split[1]) ?? 0, Double(split[2]) ?? 0)
                        self.toAddress2(lat, lon) { address in
                            topPlacesString.append((chance, address))
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        topPlacesString = topPlacesString.sorted{ $0.0 > $1.0 }
                        for place in topPlacesString {
                            let percent = "\(place.0.rounded(digits: 1))%"
                            self.images[i].label += "\(percent) - \(place.1)\n\n"
                        }
                    }
                }
            } // request
            request.imageCropAndScaleOption = .centerCrop
            
            let handler = VNImageRequestHandler(cgImage: image.cgImage!)
            try? handler.perform([request])
            
        }
        
    }
    
}

extension GeoMLModel {
    
    func toAddress2(_ latitude: Double, _ longitude: Double, completion: @escaping (String)->Void) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        var labelText = ""
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            if placeMark != nil {
                if let name = placeMark.name {
                    labelText = name
                }
                if let subThoroughfare = placeMark.subThoroughfare {
                    if (subThoroughfare != placeMark.name) && (labelText != subThoroughfare) {
                        labelText = (labelText != "") ? labelText + "," + subThoroughfare : subThoroughfare
                    }
                }
                if let subLocality = placeMark.subLocality {
                    if (subLocality != placeMark.subThoroughfare) && (labelText != subLocality) {
                        labelText = (labelText != "") ? labelText + "," + subLocality : subLocality
                    }
                }
                if let street = placeMark.thoroughfare {
                    if (street != placeMark.subLocality) && (labelText != street) {
                        labelText = (labelText != "") ? labelText + "," + street : street
                    }
                }
                if let locality = placeMark.locality {
                    if (locality != placeMark.thoroughfare) && (labelText != locality) {
                        labelText = (labelText != "") ? labelText + "," + locality : locality
                    }
                }
                if let city = placeMark.subAdministrativeArea {
                    if (city != placeMark.locality) && (labelText != city) {
                        labelText = (labelText != "") ? labelText + "," + city : city
                    }
                }
                if let country = placeMark.country {
                    labelText = (labelText != "") ? labelText + "," + country : country
                }
                completion(labelText)
            }
        })
        
    }
    
}
