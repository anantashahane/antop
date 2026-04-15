import Foundation
import Darwin

enum UIBlock {
    static let TopLeftCorner = "╭"
    static let TopRightCorner = "╮"
    static let BottomLeftCorner = "╰"
    static let BottomRightCorner = "╯"
    static let HorizontalLine = "─"
    static let VerticalLine = "│"
    static let Solid = "█"
    static let Translucent = "░"
}


//#MARK: - Helper Functions
func drawBorder(frame: Frame, into buffer: inout ScreenBuffer) {
    let w = frame.width

    // Top
    buffer.set(row: frame.start.row, col: frame.start.column, char: Character(UIBlock.TopLeftCorner))
    for i in 1..<(w - 1) {
        buffer.set(row: frame.start.row, col: frame.start.column + i, char: Character(UIBlock.HorizontalLine))
    }
    buffer.set(row: frame.start.row, col: frame.end.column, char: Character(UIBlock.TopRightCorner))

    // Bottom
    buffer.set(row: frame.end.row, col: frame.start.column, char: Character(UIBlock.BottomLeftCorner))
    for i in 1..<(w - 1) {
        buffer.set(row: frame.end.row, col: frame.start.column + i, char: Character(UIBlock.HorizontalLine))
    }
    buffer.set(row: frame.end.row, col: frame.end.column, char: Character(UIBlock.BottomRightCorner))

    // Sides
    for row in (frame.start.row + 1)..<frame.end.row {
        buffer.set(row: row, col: frame.start.column, char: Character(UIBlock.VerticalLine))
        buffer.set(row: row, col: frame.end.column, char: Character(UIBlock.VerticalLine))
    }
}


struct Frame {
    var start: (row: Int, column: Int)
    var end: (row: Int, column: Int)

    var width: Int {
        end.column - start.column + 1
    }

    var height: Int {
        end.row - start.row + 1
    }

    func inset(size: Int = 1) -> Frame {
        Frame(
            start: (start.row + size, start.column + size),
            end: (end.row - size, end.column - size)
        )
    }
}

struct ScreenBuffer {
    var width: Int
    var height: Int
    var cells: [[Character]]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.cells = Array(
            repeating: Array(repeating: " ", count: width),
            count: height
        )
    }

    mutating func set(row: Int, col: Int, char: Character) {
        guard row >= 1, col >= 1,
              row <= height, col <= width else { return }

        cells[row - 1][col - 1] = char
    }

    mutating func update(width: Int, height: Int) {
        if self.width != width || self.height != height {
            self.width = width
            self.height = height
            self.cells = Array(
                repeating: Array(repeating: " ", count: width), 
                count: height
            )
            ClearScreen()
        }
    }

    func ClearScreen() {
        print("\u{001B}[2J")
        print("\u{001B}[3J\u{001B}[2J\u{001B}[H", terminator: "")
    }

    func GetScreen() -> String {
        ClearScreen()
        let screen = self.cells.map({String($0)}).joined(separator: "\n")
        return "\(screen)"

    }
}



protocol View {
    var frame: Frame { get set }
    var height: Int? { get }
    func layout()
    func render(into buffer: inout ScreenBuffer)
}

class VStack: View {
    var frame: Frame
    private var children: [View] = []
    var name: String?
    let height: Int?
    init(frame: Frame, name: String? = nil) {
        self.frame = frame
        self.name = name
        self.height = nil
    }

    func addChild(view: View) {
        children.append(view)
    }

    func layout() {
        let inner = frame.inset()
        guard !children.isEmpty else { return }

        // 1. Measure
        var fixedHeight = 0
        var flexibleCount = 0

        for child in children {
            if let h = child.height {
                fixedHeight += h
            } else {
                flexibleCount += 1
            }
        }

        let remainingHeight = max(0, inner.height - fixedHeight)
        let flexibleHeight = flexibleCount > 0
            ? remainingHeight / flexibleCount
            : 0

        // 2. Layout
        var currentRow = inner.start.row

        for (index, child) in children.enumerated() {
            let h: Int

            if let fixed = child.height {
                h = fixed
            } else {
                // last flexible child absorbs rounding error
                let isLastFlexible =
                    child.height == nil &&
                    children[(index + 1)...].allSatisfy { $0.height != nil }

                if isLastFlexible {
                    h = inner.end.row - currentRow + 1
                } else {
                    h = flexibleHeight
                }
            }

            let endRow = currentRow + h - 1

            children[index].frame = Frame(
                start: (currentRow, inner.start.column),
                end: (endRow, inner.end.column)
            )

            child.layout()
            currentRow = endRow + 1
        }
    }

    func render(into buffer: inout ScreenBuffer) {
        drawBorder(frame: frame, into: &buffer)

        // Title
        if let name = name {
            for (i, ch) in name.enumerated() {
                buffer.set(
                    row: frame.start.row,
                    col: frame.start.column + 1 + i,
                    char: ch
                )
            }
        }

        for child in children {
            child.render(into: &buffer)
        }
    }
}

class HStack: View {
    var frame: Frame
    private var children: [View] = []
    var name: String?
    let height: Int?
    let withBorder: Bool
    init(frame: Frame, name: String? = nil, withBorder: Bool = false) {
        self.frame = frame
        self.name = name
        self.withBorder = withBorder
        self.height = nil
    }

    func addChild(view: View) {
        children.append(view)
    }

    func layout() { 
        let inner = frame.inset(size: self.withBorder ? 1 : 0)
        guard !children.isEmpty else { return }

        let childWidth = inner.width / children.count
        for i in 0..<children.count {
            let startColumn = inner.start.column + i * childWidth
            let endColumn = (i == children.count - 1)
                ? inner.end.column
                : startColumn + childWidth - 1

            children[i].frame = Frame(
                start: (inner.start.row, startColumn),
                end: (inner.end.row, endColumn)
            )
            children[i].layout()
        }
    }

    func render(into buffer: inout ScreenBuffer) {
        drawBorder(frame: frame, into: &buffer)

        // Title
        if let name = name {
            for (i, ch) in name.enumerated() {
                buffer.set(
                    row: frame.start.row,
                    col: frame.start.column + 1 + i,
                    char: ch
                )
            }
        }

        for child in children {
            child.render(into: &buffer)
        }
    }
}

class BarChart: View {
    var frame: Frame
    var title: String
    var progress: Double
    let height: Int?

    init(frame: Frame, title: String, progress: Double) {
        self.frame = frame
        self.title = title
        self.progress = progress
        self.height = 3
    }

    func layout() {

    }

    func Update(title: String, progress: Double) {
        self.title = title
        self.progress = progress
    }

    func render(into buffer: inout ScreenBuffer) {
        drawBorder(frame: frame, into: &buffer)

        let inset = self.frame.inset()
        var progress = self.progress / 100
        progress = min(1, max(progress, 0))

        var active = Int(Double(inset.width) * progress)
        for column in inset.start.column...inset.end.column {
            for row in inset.start.row...inset.end.row {
                buffer.set(row: row, col: column, char: Character(active > 0 ? UIBlock.Solid : UIBlock.Translucent))
            }
            active -= 1
        }

        for (index, character) in self.title.enumerated() {
            buffer.set(row: self.frame.start.row, col: self.frame.start.column + 1 + index, char: character)
        }
    }
}

class PowerChart: View {
    var frame: Frame
    var title: String
    var history: LimitedArray<Int>
    let height: Int?
    init(frame: Frame, title: String, history: LimitedArray<Int>) {
        self.frame = frame
        self.title = title
        self.history = history
        self.height = nil
    }

    func layout() {}

    func render(into buffer: inout ScreenBuffer) {
        drawBorder(frame: frame, into: &buffer)

        let inset = frame.inset()
        let values = history.get()
        guard !values.isEmpty else { return }

        let maxVal = max(500, history.getMax())
        let height = inset.height
        let width = inset.width

        // If more data than width → only show latest slice
        let visible = values.suffix(width)
        let visibleCount = visible.count

        // Start so that the LAST value ends at the right edge
        let startColumn = inset.end.column - visibleCount + 1
        
        for row in inset.start.row...inset.end.row {
            for column in inset.start.column...inset.end.column {
                buffer.set(row: row, col: column, char: Character(UIBlock.Translucent))
            }
        }

        for (i, value) in visible.enumerated() {
            let normalized = maxVal == 0 ? 0 : Double(value) / Double(maxVal)
            let barHeight = Int(normalized * Double(height))

            let col = startColumn + i

            for h in 0..<height {
                let row = inset.end.row - h
                if h < barHeight {
                    buffer.set(row: row, col: col, char: Character(UIBlock.Solid))
                }
            }
        }

        // Title
        for (i, ch) in title.enumerated() {
            buffer.set(
                row: frame.start.row,
                col: frame.start.column + 1 + i,
                char: ch
            )
        }
    }
}