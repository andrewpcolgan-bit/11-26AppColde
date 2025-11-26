import SwiftUI

enum BuilderDestination: Hashable {
    case library
    case build(BuildPracticeView.Mode)
    case log(BuiltPracticeTemplate)
    case detail(BuiltPracticeTemplate)
}
