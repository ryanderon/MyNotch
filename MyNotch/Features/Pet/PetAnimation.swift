import CoreGraphics

enum PetAnimation: Hashable {
    case idle
    case hungry
    case sad
    case sleep
    case dance
    case eat
    case love
    case startled

    static func current(mood: PetMood, reaction: PetReaction?) -> PetAnimation? {
        switch reaction {
        case .eating: return .eat
        case .petted: return .love
        case .startled: return .startled
        case nil: break
        }
        switch mood {
        case .happy, .content: return .idle
        case .hungry: return .hungry
        case .sad: return .sad
        case .sleeping: return .sleep
        case .dancing: return .dance
        case .ranAway: return nil
        }
    }

    /// Resting states hold a single still frame; only short reactions and dancing animate, at 8 fps
    /// (under the 12 fps budget).
    static let framesPerSecond = 8.0

    var poses: [PetPose] {
        switch self {
        case .idle: [PetPose(eyes: .open)]
        case .hungry: [PetPose(eyes: .sad, mouth: .open, accessory: .food)]
        case .sad: [PetPose(squash: 0.94, eyes: .sad)]
        case .sleep: [PetPose(squash: 0.92, eyes: .closed, accessory: .sleep)]
        case .dance: [
            PetPose(tilt: -0.14, eyes: .happy),
            PetPose(bounce: 2.5, eyes: .happy),
            PetPose(tilt: 0.14, eyes: .happy),
            PetPose(bounce: 2.5, eyes: .happy)
        ]
        case .eat: [PetPose(eyes: .happy, mouth: .open), PetPose(squash: 0.97, eyes: .happy)]
        case .love: [PetPose(squash: 1.04, eyes: .happy, accessory: .heart), PetPose(squash: 0.98, eyes: .happy, accessory: .heart)]
        case .startled: [PetPose(bounce: 3, eyes: .wide, accessory: .alert), PetPose(bounce: 1, eyes: .wide, accessory: .alert)]
        }
    }
}

struct PetPose: Equatable {
    enum Eyes: Equatable {
        case open
        case closed
        case sad
        case happy
        case wide
    }

    enum Mouth: Equatable {
        case smile
        case open
    }

    enum Accessory: Equatable {
        case sleep
        case heart
        case alert
        case food
    }

    var bounce: CGFloat = 0
    var squash: CGFloat = 1
    var tilt: CGFloat = 0
    var eyes: Eyes
    var mouth: Mouth = .smile
    var accessory: Accessory?
}
