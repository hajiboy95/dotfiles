// Prints the style name to use for a font family's regular face:
// "Regular" when the family has it, else its first upright,
// regular-weight member (Apple Chancery's only style is "Chancery").
// Prints nothing for a family that is not installed.
import AppKit

guard let family = CommandLine.arguments.dropFirst().first,
      let members = NSFontManager.shared.availableMembers(ofFontFamily: family),
      !members.isEmpty
else { exit(0) }

// Each member: [postscript name, style name, weight, traits].
let styles = members.compactMap { m -> (String, Int, UInt)? in
    guard m.count >= 4, let style = m[1] as? String,
          let weight = (m[2] as? NSNumber)?.intValue,
          let traits = (m[3] as? NSNumber)?.uintValue else { return nil }
    return (style, weight, traits)
}
let italic = NSFontTraitMask.italicFontMask.rawValue
let pick = styles.first { $0.0 == "Regular" }
    ?? styles.first { $0.1 == 5 && $0.2 & italic == 0 }
    ?? styles.first
if let pick { print(pick.0) }
