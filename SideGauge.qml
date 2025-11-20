import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 450; height: 450

    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property string title: "RPM"
    property real startAngle: -130
    property real endAngle: 130
    property real rangeAngle: endAngle - startAngle
    property real needleAngle: startAngle + ((endAngle - startAngle) * (value - minValue) / (maxValue - minValue))

    // 1. Background
    Image {
        anchors.fill: parent
        source: "qrc:/assets/Ellipse 1.svg" // Sử dụng hình Ellipse làm nền
        fillMode: Image.PreserveAspectFit
        opacity: 0.2
    }

    // 2. Tickmarks (Dùng tickmark.svg)
    Repeater {
        model: 6
        delegate: Item {
            property real angle: root.startAngle + (index * (root.rangeAngle / (model - 1)))
            anchors.centerIn: parent
            width: parent.width; height: parent.height

            Image {
                source: "qrc:/assets/tickmark.svg"
                width: 4; height: 15
                y: 30
                anchors.horizontalCenter: parent.horizontalCenter
                transform: [
                    Translate { y: -parent.height/2 },
                    Rotation { angle: angle; origin.x: parent.width/2; origin.y: parent.height/2 + 30 }
                ]
            }
        }
    }

    // 3. Progress Arc
    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d"); ctx.reset();
            var center = width/2; var radius = width/2 - 20;
            var start = (root.startAngle - 90) * Math.PI/180;
            var end = (root.needleAngle - 90) * Math.PI/180;

            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0, "#00FF00"); grad.addColorStop(1, "#FFFF00");

            ctx.beginPath(); ctx.arc(center, center, radius, start, end);
            ctx.lineWidth = 10; ctx.strokeStyle = grad; ctx.lineCap = "round"; ctx.stroke();
        }
        Connections { target: root; function onValueChanged(){ cv.requestPaint() } }
    }

    // 4. Kim Nhỏ (Dùng needle.svg nhưng thu nhỏ)
    Item {
        anchors.fill: parent
        rotation: root.needleAngle
        Behavior on rotation { SpringAnimation { spring: 2.0; damping: 0.2 } }

        Image {
            source: "qrc:/assets/needle.svg"
            width: 10; height: root.height/2 - 50
            anchors.horizontalCenter: parent.horizontalCenter
            y: 50
            fillMode: Image.PreserveAspectFit
        }
    }

    // 5. Text Info
    Column {
        anchors.centerIn: parent
        Text {
            text: (root.maxValue > 1000) ? (root.value/1000).toFixed(1) + "k" : Math.round(root.value) + "%"
            font.pixelSize: 50; font.bold: true; color: "white"
        }
        Text {
            text: title; font.pixelSize: 22; color: "#888"; font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    property bool accelerating: false
}
