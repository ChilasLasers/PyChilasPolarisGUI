/****************************************************************************
This file is part of Chilas Polaris.

Chilas Polaris is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Chilas Polaris is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
****************************************************************************/

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Extras 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.impl 2.4

Pane {
    id: pageCntrlPnl
    background: Rectangle {
        color: "transparent"
    }

    ScrollView {
        anchors.fill: parent
        wheelEnabled: true
        clip: true

        Row {
            id: rowMain
            width: 696
            height: 456
            spacing: 12

            Column {
                id: colLeft
                spacing: 12
                width: 342

                GroupBox {
                    id: groupSeial
                    title: "Serial Port"
                    width: 342
                    label: Label {
                             x: groupSeial.leftPadding
                             width: groupSeial.availableWidth
                             text: groupSeial.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupSeial.topPadding - groupSeial.bottomPadding
                        width: parent.width
                        height: parent.height - groupSeial.topPadding + groupSeial.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }

                    Row {
                        id: rowSerial
                        spacing: 12

                        ComboBox {
                            id: comboBoxCom
                            width: 98
                            font.pointSize: 10
                            popup.width: 200
                            Component.onCompleted: buttonComRef.clicked()
                            onActivated: { backend.ioPort(0, comboBoxCom.currentIndex); buttonConnect.checked = false }
                        }
                        Button {
                            id: buttonConnect
                            text: checked ? "Disconnect" : "Connect"
                            width: 98
                            font.pointSize: 10
                            checkable: true
                            onToggled: {
                                if (checked) {
                                    if (backend.ioPort(1, comboBoxCom.currentIndex) === "0") {
                                        busyIndicator.running = true
                                        textEditSn.text = backend._executor('_getSN')
                                        textEditVer.text = backend._executor('_getVer')
                                        backend._executor('_mode') == 1 ? (checkBoxSetMode.checked = 1) : (checkBoxStdMode.checked = 1)
                                        timerGModuleT.restart()
                                        timerGTec.restart()
                                        timerGLd.restart()
                                        timerGTecCur.restart()
                                        timerGStatus.restart()
                                        statusInit.active = true
                                        spinBoxTec.value = spinBoxTec.decimalToInt(parseFloat(backend._executor('_getTecTempSet')))
                                        spinBoxLd.value = spinBoxLd.decimalToInt(parseFloat(backend._executor('_getLdCurSet')))
                                        comWait.start()
                                    } else {
                                        checked = false
                                        fail.restart()
                                    }
                                } else {
                                    if (backend.ioPort(0, comboBoxCom.currentIndex) === "0") {
                                        timerGModuleT.stop()
                                        timerGTec.stop()
                                        timerGLd.stop()
                                        timerGTecCur.stop()
                                        timerGStatus.stop()
                                        statusInit.active = false
                                        statusLD.active = false
                                        statusTEC.active = false

                                    } else {
                                        checked = true
                                        fail.restart()
                                    }
                                }
                            }
                            background: Rectangle {
                                id: buttonConnectBG
                                implicitWidth: 100
                                implicitHeight: 40
                                opacity: enabled ? 1.0 : 0.3
                                color: Color.blend(buttonConnect.checked || buttonConnect.highlighted ? "#808080" : "#e0e0e0", "#aaaaaa", buttonConnect.down ? 0.5 : 0.0)
                                SequentialAnimation on color {
                                    id: fail
                                    running: false
                                    loops: 3
                                    ColorAnimation {
                                        from: buttonConnectBG.color
                                        to: "red"
                                        duration: 100
                                    }
                                    ColorAnimation {
                                        from: "red"
                                        to: buttonConnectBG.color
                                        duration: 100
                                    }
                                }
                            }
                            contentItem: Text {
                                     text: buttonConnect.text
                                     font: buttonConnect.font
                                     opacity: enabled ? 1.0 : 0.3
                                     color: "#26282a"
                                     horizontalAlignment: Text.AlignHCenter
                                     verticalAlignment: Text.AlignVCenter
                                     elide: Text.ElideRight
                                 }
                            Timer {
                                id: comWait
                                interval: 500; running: false; repeat: false
                                onTriggered: {
                                    busyIndicator.running = false
                                }
                            }
                        }

                        Button {
                            id: buttonComRef
                            text: "Refresh"
                            width: 98
                            font.pointSize: 10
                            onClicked: {
                                comboBoxCom.model = backend.listPorts()
                                busyIndicator.running = true
                                refWait.start()
                            }
                            Timer {
                                id: refWait
                                interval: 200; running: false; repeat: false
                                onTriggered: {
                                    busyIndicator.running = false
                                }
                            }
                        }
                    }
                }
                GroupBox {
                    id: groupMode
                    title: "Mode"
                    width: 342
                    label: Label {
                             x: groupMode.leftPadding
                             width: groupMode.availableWidth
                             text: groupMode.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupMode.topPadding - groupMode.bottomPadding
                        width: parent.width
                        height: parent.height - groupMode.topPadding + groupMode.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }
                    ButtonGroup {
                        buttons: rowMode.children
                    }
                    Row {
                        id: rowMode
                        spacing: 12

                        CheckBox {
                            id: checkBoxStdMode
                            text: "Standard Mode"
                            width: 158
                            font.pointSize: 10
                            onToggled: backend._executor('_mode', [!checked+0])
                        }
                        CheckBox {
                            id: checkBoxSetMode
                            text: "Setting Mode"
                            width: 158
                            font.pointSize: 10
                            onToggled: backend._executor('_mode', [checked+0])
                        }
                    }
                }
                GroupBox {
                    id: groupLaser
                    title: "Laser (Setting Mode Only)"
                    width: 342
                    enabled: checkBoxSetMode.checked
                    label: Label {
                             x: groupLaser.leftPadding
                             width: groupLaser.availableWidth
                             text: groupLaser.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupLaser.topPadding - groupLaser.bottomPadding
                        width: parent.width
                        height: parent.height - groupLaser.topPadding + groupLaser.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }

                    Column {
                        id: laserCol
                        width: 342
                        spacing: 12

                        Row {
                            id: rowTec
                            spacing: 10

                            Text {
                                id: textTec
                                width: 80
                                text: "TEC Temperature:"
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            SpinBox {
                                id: spinBoxTec
                                width: 128
                                font.pointSize: 10
                                wheelEnabled: true
                                editable: true
                                locale: Qt.locale("en_EN")
                                from: decimalToInt(0)
                                to: decimalToInt(100)
                                stepSize: decimalFactor

                                property int decimals: 2
                                property real realValue: value / decimalFactor
                                readonly property int decimalFactor: Math.pow(10, decimals)

                                function decimalToInt(decimal) {
                                    return decimal * decimalFactor
                                }

                                validator: DoubleValidator {
                                    bottom: Math.min(spinBoxTec.from, spinBoxTec.to)
                                    top:  Math.max(spinBoxTec.from, spinBoxTec.to)
                                    decimals: spinBoxTec.decimals
                                    notation: DoubleValidator.StandardNotation
                                }

                                textFromValue: function(value, locale) {
                                    return Number(value / decimalFactor).toLocaleString(locale, 'f', spinBoxTec.decimals)
                                }

                                valueFromText: function(text, locale) {
                                    return Math.round(Number.fromLocaleString(locale, text) * decimalFactor)
                                }
                            }
                            Text {
                                text: "°C"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                font.pointSize: 10
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                            }
                            Button {
                                text: "Set"
                                width: 60
                                font.pointSize: 10
                                onClicked: backend._executor('_setTecTemp', [spinBoxTec.realValue])
                            }
                        }

                        Row {
                            id: rowLd
                            spacing: 10

                            Text {
                                id: textLd
                                width: 80
                                text: "Laser Diode Current:"
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            SpinBox {
                                id: spinBoxLd
                                width: 128
                                font.pointSize: 10
                                wheelEnabled: true
                                editable: true
                                locale: Qt.locale("en_EN")
                                from: decimalToInt(0)
                                to: decimalToInt(500)
                                stepSize: decimalFactor

                                property int decimals: 2
                                property real realValue: value / decimalFactor
                                readonly property int decimalFactor: Math.pow(10, decimals)

                                function decimalToInt(decimal) {
                                    return decimal * decimalFactor
                                }

                                validator: DoubleValidator {
                                    bottom: Math.min(spinBoxLd.from, spinBoxLd.to)
                                    top:  Math.max(spinBoxLd.from, spinBoxLd.to)
                                    decimals: spinBoxLd.decimals
                                    notation: DoubleValidator.StandardNotation
                                }

                                textFromValue: function(value, locale) {
                                    return Number(value / decimalFactor).toLocaleString(locale, 'f', spinBoxLd.decimals)
                                }

                                valueFromText: function(text, locale) {
                                    return Math.round(Number.fromLocaleString(locale, text) * decimalFactor)
                                }
                            }
                            Text {
                                text: "mA"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 10
                            }
                            Button {
                                text: "Set"
                                width: 60
                                font.pointSize: 10
                                onClicked: backend._executor('_setLdCur', [spinBoxLd.realValue])
                            }
                        }
                        Button {
                            id: buttonLd
                            width: 318
                            text: checked ? "Close Laser Diode" : "Open Laser Diode"
                            font.pointSize: 10
                            checkable: true
                            background: Rectangle {
                                id: buttonLdBG
                                implicitWidth: 100
                                implicitHeight: 40
                                opacity: enabled ? 1.0 : 0.3
                                color: Color.blend(buttonLd.checked || buttonLd.highlighted ? "#808080" : "#e0e0e0", "#aaaaaa", buttonLd.down ? 0.5 : 0.0)
                            }
                            contentItem: Text {
                                     text: buttonLd.text
                                     font: buttonLd.font
                                     opacity: enabled ? 1.0 : 0.3
                                     color: "#26282a"
                                     horizontalAlignment: Text.AlignHCenter
                                     verticalAlignment: Text.AlignVCenter
                                     elide: Text.ElideRight
                            }
                            onToggled: backend._executor('_setLd', [checked+0])
                        }
                    }
                }
                Item {
                    width: 342
                    height: 79

                    Image {
                        id: image
                        source: "polaris_logo.png"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        antialiasing: true
                    }

                }


            }
            Column {
                id: colRight
                spacing: 12
                width: 342

                GroupBox {
                    id: groupStatus
                    title: "Module Status"
                    width: 342
                    label: Label {
                             x: groupStatus.leftPadding
                             width: groupStatus.availableWidth
                             text: groupStatus.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupStatus.topPadding - groupStatus.bottomPadding
                        width: parent.width
                        height: parent.height - groupStatus.topPadding + groupStatus.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }

                    Row {
                        id: rowStatus
                        spacing: 12

                        Column {
                            id: colInit
                            width: 98
                            spacing: 10

                            Text {
                                text: "Initializing"
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pointSize: 10
                            }
                            StatusIndicator {
                                id: statusInit
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: '#F47A21'
                            }
                        }
                        Column {
                            id: colTEC
                            width: 98
                            spacing: 10

                            Text {
                                text: "TEC"
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pointSize: 10
                            }
                            StatusIndicator {
                                id: statusTEC
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: 'green'
                            }
                        }
                        Column {
                            id: colLD
                            width: 98
                            spacing: 10

                            Text {
                                text: "Laser Diode"
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pointSize: 10
                            }
                            StatusIndicator {
                                id: statusLD
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: 'red'
                            }
                        }

                        Timer {
                            id: timerGStatus
                            interval: 200
                            running: false
                            repeat: true
                            triggeredOnStart: true
                            property int stat: 0
                            onTriggered: {
                                stat = backend._executor('_getDevStat')
                                statusTEC.active = stat & 2
                                statusLD.active = stat & 4
                                buttonLd.checked = stat & 4
                                if (statusTEC.active & statusLD.active) {
                                    statusInit.active = false
                                }
                            }
                        }
                    }
                }
                GroupBox {
                    id: groupResponse
                    title: "Module Response Data"
                    width: 342
                    label: Label {
                             x: groupResponse.leftPadding
                             width: groupResponse.availableWidth
                             text: groupResponse.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupResponse.topPadding - groupResponse.bottomPadding
                        width: parent.width
                        height: parent.height - groupResponse.topPadding + groupResponse.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }

                    Column {
                        id: colResponse
                        width: parent.width
                        spacing: 12

                        Row {
                            id: rowGTec
                            spacing: 10

                            Text {
                                id: textGTec
                                text: "TEC Temperature:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditGTec
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10
                                }
                                Timer {
                                    id: timerGTec
                                    interval: 1000
                                    running: false
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: textEditGTec.text = backend._executor('_getTecTemp')
                                }
                            }
                            Text {
                                text: "°C"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 10
                            }
                        }
                        Row {
                            id: rowGLd
                            spacing: 10

                            Text {
                                id: textGLd
                                text: "Laser Diode Current:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditGLd
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10
                                }
                                Timer {
                                    id: timerGLd
                                    interval: 1000
                                    running: false
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: textEditGLd.text = backend._executor('_getLdCur')
                                }
                            }
                            Text {
                                text: "mA"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 10
                            }
                        }
                        Row {
                            id: rowGTecCur
                            spacing: 10

                            Text {
                                id: textGTecCur
                                text: "TEC Current:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditGTecCur
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10
                                }
                                Timer {
                                    id: timerGTecCur
                                    interval: 1000
                                    running: false
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: textEditGTecCur.text = backend._executor('_getTecCur')
                                }
                            }
                            Text {
                                text: "mA"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 10
                            }
                        }
                        Row {
                            id: rowGModuleT
                            spacing: 10

                            Text {
                                id: textGModuleT
                                text: "Module Temperature:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditGModuleT
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10

                                    Timer {
                                        id: timerGModuleT
                                        interval: 1000
                                        running: false
                                        repeat: true
                                        triggeredOnStart: true
                                        onTriggered: textEditGModuleT.text = backend._executor('_getPcbTemp')
                                    }
                                }
                            }
                            Text {
                                text: "°C"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 10
                            }
                        }
                    }
                }
                GroupBox {
                    id: groupInfo
                    title: "Module Information"
                    width: 342
                    label: Label {
                             x: groupInfo.leftPadding
                             width: groupInfo.availableWidth
                             text: groupInfo.title
                             verticalAlignment: Text.AlignVCenter
                             font.pointSize: 14
                             color: "#FFFFFF"

                         }
                    background: Rectangle {
                        y: groupInfo.topPadding - groupInfo.bottomPadding
                        width: parent.width
                        height: parent.height - groupInfo.topPadding + groupInfo.bottomPadding
                        color: "#FFFFFF"
                        opacity: 0.7
                    }

                    Column {
                        id: colInfo
                        width: parent.width
                        spacing: 12

                        Row {
                            id: rowSn
                            spacing: 10

                            Text {
                                id: textSn
                                text: "Module SN Code:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditSn
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10
                                }
                            }
                        }
                        Row {
                            id: rowVer
                            spacing: 10

                            Text {
                                id: textVer
                                text: "Module Version:"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                            }
                            Rectangle {
                                width: 178
                                height: 35
                                color: "#FFFFFF"

                                TextEdit {
                                    id: textEditVer
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    readOnly: true
                                    text: "-"
                                    font.pointSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.verticalCenter: parent.verticalCenter
        antialiasing: true
        running: false
        anchors.horizontalCenter: parent.horizontalCenter
    }
}





