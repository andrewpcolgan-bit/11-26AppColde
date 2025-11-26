import Foundation


struct MockData {
static let samplePractice: Practice = {
let warmup = Block(type: .warmup, sets: [
.init(description: "400 swim + 200 drill", yards: 600, stroke: .free, intensity: .easy)
])
let preset = Block(type: .preset, sets: [
.init(description: "8x50 IM order @ :55", yards: 400, stroke: .im, intensity: .aerobic),
.init(description: "4x100 kick @1:40", yards: 400, stroke: .kick, intensity: .aerobic)
])
let mainset = Block(type: .mainset, sets: [
.init(description: "8x100 free @1:20 desc 1–4 x2", yards: 800, stroke: .free, intensity: .threshold),
.init(description: "4x50 fly fast @1:00", yards: 200, stroke: .fly, intensity: .sprint),
.init(description: "4x100 pull paddles @1:30", yards: 400, stroke: .free, intensity: .aerobic)
])
let cooldown = Block(type: .cooldown, sets: [
.init(description: "200 easy", yards: 200, stroke: .free, intensity: .easy)
])
return Practice(date: Date(), sessionLabel: "AM", blocks: [warmup, preset, mainset, cooldown])
}()


static let thisWeek: [Practice] = {
let days = (0..<5).map { i -> Practice in
var comp = DateComponents()
comp.day = -i
let d = Calendar.current.date(byAdding: comp, to: Date())!
var p = samplePractice
return Practice(date: d, sessionLabel: i % 2 == 0 ? "AM" : "PM", blocks: p.blocks)
}
return days
}()
}
