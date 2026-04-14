import Foundation
import Darwin

  
  
enum UIBlock {
    static let TopLeftCorner = "╭"
    static let TopRightCorner = "╮"
    static let BottomLeftCorner = "╰"
    static let BottomRightCorner = "╯"
    static let HorizontalLine = "─"
    static let VerticalLine = "│"
}


//#MARK: - Helper Functions
func drawBorder(frame: Frame, into buffer: inout ScreenBuffer) {
    let w = frame.width

    // Top
    buffer.set(row: frame.start.row, col: frame.start.col, char: Character(UIBlock.TopLeftCorner))
    for i in 1..<(w - 1) {
        buffer.set(row: frame.start.row, col: frame.start.col + i, char: Character(UIBlock.HorizontalLine))
    }
    buffer.set(row: frame.start.row, col: frame.end.col, char: Character(UIBlock.TopRightCorner))

    // Bottom
    buffer.set(row: frame.end.row, col: frame.start.col, char: Character(UIBlock.BottomLeftCorner))
    for i in 1..<(w - 1) {
        buffer.set(row: frame.end.row, col: frame.start.col + i, char: Character(UIBlock.HorizontalLine))
    }
    buffer.set(row: frame.end.row, col: frame.end.col, char: Character(UIBlock.BottomRightCorner))

    // Sides
    for row in (frame.start.row + 1)..<frame.end.row {
        buffer.set(row: row, col: frame.start.col, char: Character(UIBlock.VerticalLine))
        buffer.set(row: row, col: frame.end.col, char: Character(UIBlock.VerticalLine))
    }
}


struct Frame {
    var start: (row: Int, col: Int)
    var end: (row: Int, col: Int)

    var width: Int {
        end.col - start.col + 1
    }

    var height: Int {
        end.row - start.row + 1
    }

    func inset() -> Frame {
        Frame(
            start: (start.row + 1, start.col + 1),
            end: (end.row - 1, end.col - 1)
        )
    }
}

struct ScreenBuffer {
    let width: Int
    let height: Int
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
}



protocol View {
    var frame: Frame { get set }

    func layout()
    func render(into buffer: inout ScreenBuffer)
}

class VStack: View {
    var frame: Frame
    private var children: [View] = []
    var name: String?

    init(frame: Frame, name: String? = nil) {
        self.frame = frame
        self.name = name
    }

    func addChild(view: View) {
        children.append(view)
    }

    func layout() {
        let inner = frame.inset()
        guard !children.isEmpty else { return }

        let childHeight = inner.height / children.count
        for i in 0..<children.count {
            let startRow = inner.start.row + i * childHeight
            let endRow = (i == children.count - 1)
                ? inner.end.row
                : startRow + childHeight - 1

            children[i].frame = Frame(
                start: (startRow, inner.start.col),
                end: (endRow, inner.end.col)
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
                    col: frame.start.col + 1 + i,
                    char: ch
                )
            }
        }

        for child in children {
            child.render(into: &buffer)
        }
    }
}