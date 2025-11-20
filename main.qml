import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "./"

ApplicationWindow {
    id: appWindow
    width: 1920
    height: 960
    visible: true
    title: qsTr("Neon EV Dashboard - High Visibility")
    color: "#000000"

    // --- 1. SYSTEM STATES ---
    property real currentSpeed: 0
    property real currentRpm: 0
    property real currentBattery: 67
    property int nextSpeedTarget: 0
    property string gear: "P"
    property bool lowBeamActive: false
    property real roadAnimOffset: 0

    // --- 2. LOGIC ---
    function getPowerBarColor(index, totalBars) {
        let loadFactor = currentSpeed / 250.0;
        let barPosition = index / totalBars;
        if (barPosition > loadFactor) return "#1A2A2A";
        if (loadFactor < 0.6) return "#00FF99";
        if (loadFactor < 0.85) return "#FFFF00";
        return "#FF3333";
    }

    function generateRandom(maxLimit) {
        if (maxLimit === undefined) maxLimit = 250
        return Math.floor(Math.random() * maxLimit)
    }

    // --- 3. PHYSICS LOOP ---
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            var maxAllowedSpeed = (gear == "P" || gear == "N") ? 0 : 250;
            var target = speedGauge.accelerating ? maxAllowedSpeed : nextSpeedTarget;
            if (gear == "R") target = 30;

            currentSpeed += (target - currentSpeed) * 0.02;
            currentRpm = currentSpeed * 32;
            currentBattery = Math.max(0, currentBattery - (currentSpeed * 0.00005));

            // Animation đường đi nhanh hơn chút để tạo cảm giác tốc độ
            roadAnimOffset = (roadAnimOffset + currentSpeed * 0.15) % 50;

            speedGauge.value = Math.abs(currentSpeed);
            leftGauge.value = currentRpm;
            rightGauge.value = currentBattery;
        }
    }

    Timer {
        interval: 3000; running: true; repeat: true;
        onTriggered: { if (!speedGauge.accelerating && gear == "D") nextSpeedTarget = generateRandom(220) }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { currentTimeLabel.text = Qt.formatDateTime(new Date(), "HH:mm"); currentDateLabel.text = Qt.formatDateTime(new Date(), "dd/MM/yyyy") }
    }

    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }

    // --- 4. GIAO DIỆN HMI ---
    Rectangle {
        id: dashboardContainer
        anchors.fill: parent
        color: "transparent"
        focus: true
        Component.onCompleted: forceActiveFocus()

        // LAYER 0: BACKGROUND
        Image {
            anchors.fill: parent
            source: "qrc:/assets/background.png"
            fillMode: Image.PreserveAspectCrop
        }

        // LAYER 1: DASHBOARD FRAME
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.98
            height: parent.height * 0.95
            source: "qrc:/assets/Dashboard.svg"
            fillMode: Image.PreserveAspectFit
        }

        // LAYER 2: DECORATION VECTORS (Tăng opacity để đậm hơn)
        Image {
            source: "qrc:/assets/Vector_2.svg"
            width: 150; height: 600
            anchors.left: parent.left; anchors.leftMargin: 50
            anchors.verticalCenter: parent.verticalCenter
            opacity: 1.0 // Đậm hơn (cũ là 0.8)
        }
        Image {
            source: "qrc:/assets/Vector_1.svg"
            width: 150; height: 600
            anchors.right: parent.right; anchors.rightMargin: 50
            anchors.verticalCenter: parent.verticalCenter
            opacity: 1.0 // Đậm hơn
        }

        // LAYER 3: TOP BAR
        Item {
            id: topBar
            width: parent.width * 0.7; height: 100
            anchors.top: parent.top; anchors.topMargin: 35
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                anchors.fill: parent
                source: "qrc:/assets/Vector_70.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 1.0 // Đậm tối đa
            }

            // Nội dung Top Bar
            Image {
                width: 40; height: 40
                anchors.left: parent.left; anchors.leftMargin: 80; anchors.verticalCenter: parent.verticalCenter
                source: lowBeamActive ? "qrc:/assets/Low beam headlights.svg" : "qrc:/assets/Low_beam_headlights_white.svg"
                opacity: lowBeamActive ? 1.0 : 0.7 // Tăng độ đậm khi tắt
            }
            Text { id: currentTimeLabel; text: "00:00"; font.pixelSize: 32; font.bold: true; color: "white"; anchors.centerIn: parent }
            Text { id: currentDateLabel; text: "20/11/2025"; font.pixelSize: 24; font.bold: true; color: "white"; anchors.right: parent.right; anchors.rightMargin: 80; anchors.verticalCenter: parent.verticalCenter }
        }

        // LAYER 4: GAUGE CLUSTER (Nâng cấp spacing + layout EV style)
        Item {
            id: gaugeCluster
            width: parent.width * 0.92        // thu hẹp vùng chứa → gauges gần nhau
            height: 480
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100            // đẩy cả cụm lên cao

            SideGauge {
                id: leftGauge
                title: "RPM"; minValue: 0; maxValue: 8000
                width: 310; height: 310        // thu nhỏ đẹp hơn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 215       // giảm từ 120 → 60
            }

            Gauge {
                id: speedGauge
                gaugeLabel: "KM/H"
                minimumValue: 0; maximumValue: 250
                width: 330; height: 330        // cân đối nhất với xe
                anchors.centerIn: parent
            }

            SideGauge {
                id: rightGauge
                title: "BATTERY"; minValue: 0; maxValue: 100
                width: 310; height: 310
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 215       // giảm từ 120 → 60
            }
        }


        // LAYER 5: CENTER CONSOLE (Xe + Đường)
        Item {
            id: centerInfo
            width: 300; height: 350
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 150   // đảm bảo không chạm vào speedGauge

            Image {
                width: 150; height: 200
                anchors.centerIn: parent
                source: "qrc:/assets/road.svg"
                opacity: 0.7
                y: roadAnimOffset
                z: -1
            }

            Image {
                id: carImg
                width: 150; height: 150
                anchors.centerIn: parent
                y: 20
                source: "qrc:/assets/Car.svg"
                opacity: 1.0
                x: parent.width/2 - width/2 + (Math.random() - 0.5) * (currentSpeed/100)
            }

            Rectangle {
                width: 70; height: 70; radius: 35
                color: "#F0F0F0"
                border.color: "#CC0000"; border.width: 5
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    text: nextSpeedTarget.toFixed(0)
                    font.pixelSize: 28; font.bold: true; color: "black"
                    anchors.centerIn: parent
                }
            }
        }


        // LAYER 6: INDICATORS (Căn chỉnh theo gaugeCluster)
        ColumnLayout {
            spacing: 26
            anchors.left: parent.left
            anchors.leftMargin: 55
            anchors.verticalCenter: gaugeCluster.verticalCenter
            anchors.verticalCenterOffset: -20  // đưa icon lên nhẹ để cân đối

            Image { width: 50; height: 50; source: "qrc:/assets/Parking lights.svg"; opacity: 1.0 }
            Image { width: 50; height: 50; source: "qrc:/assets/Lights.svg"; opacity: 1.0 }
            Image { width: 50; height: 50; source: "qrc:/assets/Low beam headlights.svg"; opacity: lowBeamActive ? 1.0 : 1.0 }
            Image { width: 50; height: 50; source: "qrc:/assets/Rare fog lights.svg"; opacity: 1.0 }
        }

        ColumnLayout {
            spacing: 26
            anchors.right: parent.right
            anchors.rightMargin: 55
            anchors.verticalCenter: gaugeCluster.verticalCenter
            anchors.verticalCenterOffset: -20

            Image { width: 46; height: 46; source: "qrc:/assets/FirstRightIcon.svg"; opacity: 0.9 }
            Image { width: 50; height: 40; source: "qrc:/assets/SecondRightIcon.svg"; opacity: 0.9 }
            Image { width: 50; height: 40; source: "qrc:/assets/thirdRightIcon.svg"; opacity: 0.9 }
            Image { width: 50; height: 40; source: "qrc:/assets/FourthRightIcon.svg"; opacity: 0.9 }
        }


        // LAYER 7: BOTTOM BAR
        Rectangle {
            id: bottomBar
            width: parent.width * 0.85; height: 100
            color: "transparent"
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20; anchors.horizontalCenter: parent.horizontalCenter

            RowLayout {
                anchors.fill: parent

                Text { text: "100.6 °F"; font.pixelSize: 28; color: "white"; font.bold: true }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 15
                    Image { width: 35; height: 35; source: "qrc:/assets/fuel.svg"; fillMode: Image.PreserveAspectFit; opacity: 1.0 } // Icon pin đậm
                    Row {
                        spacing: 4
                        Repeater {
                            model: 20
                            Rectangle {
                                width: 12; height: 25; radius: 2
                                color: getPowerBarColor(index, 20)
                                transform: Rotation { origin.x: 6; origin.y: 12.5; angle: 15 }
                            }
                        }
                    }
                    Text { text: Math.round(currentSpeed) + " MPH"; font.pixelSize: 28; color: "white"; font.bold: true; leftPadding: 10 }
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 25
                    Text { text: "P"; font.pixelSize: 32; color: gear == "P" ? "#00FFFF" : "#888"; font.bold: true } // Màu xám sáng hơn
                    Text { text: "R"; font.pixelSize: 32; color: gear == "R" ? "#FF3333" : "#888"; font.bold: true }
                    Text { text: "N"; font.pixelSize: 32; color: gear == "N" ? "white" : "#888"; font.bold: true }
                    Text { text: "D"; font.pixelSize: 32; color: gear == "D" ? "#00FF99" : "#888"; font.bold: true }
                }
            }
        }

        // --- INPUT ---
        Keys.onPressed: {
            if (event.key === Qt.Key_Space) speedGauge.accelerating = true;
            if (event.key === Qt.Key_Left) leftGauge.accelerating = true;
            if (event.key === Qt.Key_Right) rightGauge.accelerating = true;
            if (event.key === Qt.Key_L) lowBeamActive = !lowBeamActive;
            if (event.key === Qt.Key_P) gear = "P"; if (event.key === Qt.Key_R) gear = "R";
            if (event.key === Qt.Key_D) gear = "D"; if (event.key === Qt.Key_N) gear = "N";
            event.accepted = true;
        }
        Keys.onReleased: {
            if (event.key === Qt.Key_Space) speedGauge.accelerating = false;
            if (event.key === Qt.Key_Left) leftGauge.accelerating = false;
            if (event.key === Qt.Key_Right) rightGauge.accelerating = false;
            event.accepted = true;
        }
    }
}
