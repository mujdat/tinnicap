import Foundation
import CoreAudio

struct AudioDevice: Hashable, Codable {
    let id: AudioDeviceID
    let name: String
    let transportType: TransportType
    var volume: Float

    enum TransportType: String, Codable {
        case builtIn = "Built-in"
        case bluetooth = "Bluetooth"
        case usb = "USB"
        case hdmi = "HDMI"
        case displayPort = "DisplayPort"
        case thunderbolt = "Thunderbolt"
        case other = "Other"

        var icon: String {
            switch self {
            case .builtIn:
                return "speaker.wave.2"
            case .bluetooth:
                return "headphones"
            case .usb, .hdmi, .displayPort, .thunderbolt:
                return "cable.connector"
            case .other:
                return "speaker"
            }
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.id == rhs.id
    }
}

enum EnforcementMode: String, Codable {
    case hardCap
    case warning
}
