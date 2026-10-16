import QtQuick
import QtQuick.Shapes
import qs.Commons as Commons

// Vector equivalent of flolinr.svg; the stroke follows the current theme.
Item {
    id: root
    property color color: Commons.Color.foreground
    property real contentScale: 0.75
    implicitWidth: 24
    implicitHeight: 24
    Shape {
        x: root.width * (1 - root.contentScale) / 2
        y: root.height * (1 - root.contentScale) / 2
        width: 24; height: 24
        transform: Scale { xScale: root.width / 24 * root.contentScale; yScale: root.height / 24 * root.contentScale }
        ShapePath {
            strokeColor: root.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M3 6 H21 M9 12 H21 M9 18 H21" }
        }
    }
}
