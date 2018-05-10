import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2

import Qt.labs.platform 1.0 as Labs

import VirtScreen.DisplayProperty 1.0
import VirtScreen.Backend 1.0


ApplicationWindow {
    id: window
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Basic layouts"

    Material.theme: Material.Light
    Material.accent: Material.Teal

    property int margin: 11
    width: 380
    height: 600

    // hide screen when loosing focus
    onActiveFocusItemChanged: {
        if ((!activeFocusItem) && (!sysTrayIcon.clicked)) {
            this.hide();
        }
    }

    // virtscreen.py backend.
    Backend {
        id: backend
    }

    DisplayProperty {
        id: display
    }

    // Timer object and function
    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function() {
                timer.triggered.disconnect(cb);
            });
            timer.start();
        }
    }

    header: TabBar {
        id: tabBar
        position: TabBar.Header
        width: parent.width
        currentIndex: 0

        TabButton {
            text: qsTr("Display")
        }

        TabButton {
            text: qsTr("VNC")
        }
    }

    StackLayout {
        width: parent.width
        currentIndex: tabBar.currentIndex

        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: margin
            
            GroupBox {
                title: "Virtual Display"
                // font.bold: true
                anchors.left: parent.left
                anchors.right: parent.right

                enabled: backend.virtScreenCreated ? false : true
                
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    RowLayout {
                        Label { text: "Width"; Layout.fillWidth: true }
                        SpinBox {
                            value: backend.virt.width
                            from: 640
                            to: 1920
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                backend.virt.width = value;
                            }
                            textFromValue: function(value, locale) { return value; }
                        }
                    }

                    RowLayout {
                        Label { text: "Height"; Layout.fillWidth: true }
                        SpinBox {
                            value: backend.virt.height
                            from: 360
                            to: 1080
                            stepSize : 1
                            editable: true
                            onValueModified: {
                                backend.virt.height = value;
                            }
                            textFromValue: function(value, locale) { return value; }
                        }
                    }

                    RowLayout {
                        Label { text: "Portrait Mode"; Layout.fillWidth: true }
                        Switch {
                            checked: backend.portrait
                            onCheckedChanged: {
                                backend.portrait = checked;
                            }
                        }
                    }

                    RowLayout {
                        Label { text: "HiDPI (2x resolution)"; Layout.fillWidth: true }
                        Switch {
                            checked: backend.hidpi
                            onCheckedChanged: {
                                backend.hidpi = checked;
                            }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Label { id: deviceLabel; text: "Device"; }
                        ComboBox {
                            id: deviceComboBox
                            anchors.left: deviceLabel.right
                            anchors.right: parent.right
                            anchors.leftMargin: 120

                            textRole: "name"
                            model: backend.screens
                            currentIndex: backend.virtScreenIndex

                            onActivated: function(index) {
                                backend.virtScreenIndex = index
                            } 

                            delegate: ItemDelegate {
                                width: deviceComboBox.width
                                text: modelData.name
                                font.weight: deviceComboBox.currentIndex === index ? Font.DemiBold : Font.Normal
                                highlighted: ListView.isCurrentItem
                                enabled: modelData.connected ? false : true
                            }
                        }
                    }
                }
            }

            Button {
                id: virtScreenButton
                text: backend.virtScreenCreated ? "Disable Virtual Screen" : "Enable Virtual Screen"

                anchors.left: parent.left
                anchors.right: parent.right
                // Material.background: Material.Teal
                // Material.foreground: Material.Grey
                enabled: backend.vncState == Backend.OFF ? true : false

                Popup {
                    id: busyDialog
                    modal: true
                    closePolicy: Popup.NoAutoClose

                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2

                    BusyIndicator {
                        x: (parent.width - width) / 2
                        y: (parent.height - height) / 2
                        running: true
                    }
                }

                onClicked: {
                    busyDialog.open();
                    // Give a very short delay to show busyDialog.
                    timer.setTimeout (function() {
                        if (!backend.virtScreenCreated) {
                            backend.createVirtScreen();
                        } else {
                            backend.deleteVirtScreen();
                        }
                    }, 200);
                }

                Component.onCompleted: {
                    backend.onVirtScreenCreatedChanged.connect(function(created) {
                        busyDialog.close();
                    });
                }
            }
        }

        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: margin

            GroupBox {
                title: "VNC Server"
                anchors.left: parent.left
                anchors.right: parent.right

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    RowLayout {
                        Label { text: "Port"; Layout.fillWidth: true }
                        SpinBox {
                            value: backend.vncPort
                            from: 1
                            to: 65535
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                backend.vncPort = value;
                            }
                            textFromValue: function(value, locale) { return value; }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Label { id: passwordLabel; text: "Password" }
                        TextField {
                            anchors.left: passwordLabel.right
                            anchors.right: parent.right
                            anchors.margins: margin

                            placeholderText: "Password";
                            text: backend.vncPassword;
                            echoMode: TextInput.Password;
                            onTextEdited: {
                                backend.vncPassword = text;
                            }
                        }
                    }
                }
            }

            Button {
                id: vncButton
                anchors.left: parent.left
                anchors.right: parent.right

                text: backend.vncState == Backend.OFF ? "Start VNC Server" : "Stop VNC Server"
                enabled: backend.virtScreenCreated ? true : false
                // Material.background: Material.Teal
                // Material.foreground: Material.Grey
                onClicked: backend.vncState == Backend.OFF ? backend.startVNC() : backend.stopVNC()
            }

            ListView {
                // width: 180;
                height: 200
                anchors.left: parent.left
                anchors.right: parent.right

                model: backend.ipAddresses
                delegate: Text {
                    text: modelData
                }
            }
        }
    }

    footer: ToolBar {
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: margin
            
            Label {
                id: vncStateLabel
                text: backend.vncState == Backend.OFF ? "Off" :
                      backend.vncState == Backend.WAITING ? "Waiting" :
                      backend.vncState == Backend.CONNECTED ? "Connected" :
                      "Server state error!"
            }
            Item { Layout.fillWidth: true }
            CheckBox {
                id: enabler
                text: "Server Enabled"
                checked: true
            }
        }
    }

    // Sytray Icon
    Labs.SystemTrayIcon {
        id: sysTrayIcon
        iconSource: "icon/icon.png"
        visible: true
        property bool clicked: false

        onMessageClicked: console.log("Message clicked")
        Component.onCompleted: {
            // without delay, the message appears in a wierd place 
            timer.setTimeout (function() {
                showMessage("VirtScreen is running",
                    "The program will keep running in the system tray.\n" +
                    "To terminate the program, choose \"Quit\" in the \n" +
                    "context menu of the system tray entry.");
            }, 1500);
        }

        onActivated: function(reason) {
            console.log(reason);
            if (reason == Labs.SystemTrayIcon.Context) {
                return;
            }
            if (window.visible) {
                window.hide();
                return;
            }
            sysTrayIcon.clicked = true;
            // Move window to the corner of the primary display
            var primary = backend.primary;
            var width = primary.width;
            var height = primary.height;
            var cursor_x = backend.cursor_x - primary.x_offset;
            var cursor_y = backend.cursor_y - primary.y_offset;
            var x_mid = width / 2;
            var y_mid = height / 2;
            var x = width - window.width; //(cursor_x > x_mid)? width - window.width : 0;
            var y = (cursor_y > y_mid)? height - window.height : 0;
            x += primary.x_offset;
            y += primary.y_offset;
            window.x = x;
            window.y = y;
            window.show();
            window.raise();
            window.requestActivate();
            timer.setTimeout (function() {
                sysTrayIcon.clicked = false;
            }, 200);
        }

        menu: Labs.Menu {
            Labs.MenuItem {
                text: qsTr("&Quit")
                onTriggered: backend.quitProgram()
            }
        }
    }
}
