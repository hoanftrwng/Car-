import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 550; height: 550

    property real value: 0
    property real minimumValue: 0
    property real maximumValue: 250
    property string gaugeLabel: "KM/H"

    property real startAngle: -140
    property real endAngle: 140
    property real rangeAngle: endAngle - startAngle
    property real needleAngle: startAngle + (rangeAngle * (value - minimumValue) / (maximumValue - minimumValue))

    // 1. Background & Rings (Dùng ảnh vector nếu có, ở đây giả lập nền tròn)
    Rectangle {
        anchors.fill: parent
        radius: width/2
        color: "#080808"
        border.color: "#222"
        border.width: 2

        // Vòng tròn trang trí bên trong
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.7; height: parent.height * 0.7
            source: "qrc:/assets/ring.svg" // Nếu ko có file này thì dùng Canvas, nhưng theo list bạn có ring.svg
            opacity: 0.3
            fillMode: Image.PreserveAspectFit
        }
    }

    // 2. Tickmarks (Dùng ảnh tickmark.svg)
    Repeater {
        model: 11 // 0, 25, 50 ...
        delegate: Item {
            property real angle: root.startAngle + (index * (root.rangeAngle / (model - 1)))
            property real val: index * (root.maximumValue / (model - 1))
            anchors.centerIn: parent
            width: parent.width; height: parent.height

            // Ảnh vạch chia
            Image {
                source: "qrc:/assets/tickmark.svg"
                width: 6; height: 20
                y: 40
                anchors.horizontalCenter: parent.horizontalCenter
                transform: [
                    Translate { y: -parent.height/2 },
                    Rotation { angle: parent.angle; origin.x: parent.width/2; origin.y: parent.height/2 + 40 }
                ]
                antialiasing: true
            }

            // Số
            Text {
                text: val.toFixed(0)
                color: "white"
                font.pixelSize: 20; font.bold: true; font.family: "Arial"
                anchors.centerIn: parent
                transform: [
                    Translate { y: -parent.height/2 + 75 },
                    Rotation { angle: parent.angle; origin.x: parent.width/2; origin.y: parent.height/2 - 75 },
                    Rotation { angle: -parent.angle }
                ]
            }
        }
    }

    // 3. Progress Arc (Vẫn dùng Canvas vì nó cần động)
    Canvas {
        id: progressCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d"); ctx.reset();
            var center = width/2; var radius = width/2 - 20;
            var start = (root.startAngle - 90) * Math.PI/180;
            var end = (root.needleAngle - 90) * Math.PI/180;

            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0, "#00FFFF"); grad.addColorStop(1, "#FF0088");

            ctx.beginPath();
            ctx.arc(center, center, radius, start, end);
            ctx.lineWidth = 15; ctx.strokeStyle = grad; ctx.lineCap = "round"; ctx.stroke();
        }
        Connections { target: root; function onValueChanged(){ progressCanvas.requestPaint() } }
    }

    // 4. Kim Đồng Hồ (Dùng needle.svg)
    Item {
        id: needleContainer
        anchors.fill: parent
        rotation: root.needleAngle
        Behavior on rotation { SpringAnimation { spring: 2.0; damping: 0.2 } } // Hiệu ứng nảy kim thực tế

        Image {
            source: "qrc:/assets/needle.svg"
            width: 15; height: root.height/2 - 40
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            fillMode: Image.PreserveAspectFit
            antialiasing: true
        }
    }

    // 5. Info Center
    Column {
        anchors.centerIn: parent
        spacing: -5
        Text { text: Math.round(root.value); font.pixelSize: 100; font.bold: true; color: "white" }
        Text { text: root.gaugeLabel; font.pixelSize: 24; color: "#00FFFF"; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
    }
    property bool accelerating: false
}
