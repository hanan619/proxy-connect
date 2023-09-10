import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Dialogs 1.0
import Core 1.0

ApplicationWindow {
    id: applicationWindow
    width: 360
    height: 600
    visible: true
    title: qsTr("pConnect")

    property ListModel serverList: ListModel {}
    property int timeElapsed: 0

    function refreshList(path){
        serverList.clear();
        busy.visible = true;
        core.updateServerList(path);
    }

    Timer {
        id: timer
        interval: 1000 // i set to 10 for testing for faster results, but worked on 100 also
        running: false
        repeat: true
        onTriggered: {
            timeElapsed = timeElapsed + 1;
            var secs = timeElapsed;
            var mins = parseInt((secs / 60) % 60);
            var hours = parseInt((secs / 3600));
            secs = parseInt(secs % 60)
            var timeString = hours.toString().padStart(2, '0') + ':' +
                    mins.toString().padStart(2, '0') + ':' +
                    secs.toString().padStart(2, '0');
            timeElapsedLabel.text = timeString;
        }
    }

    header: ToolBar {
        Material.foreground: "white"
        Label {
            anchors.fill: parent
            text: "P-Connect"
            font.pixelSize: 20
            font.bold: true
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }
    }

    footer: ToolBar {
        height: 24
        Material.foreground: "white"
        RowLayout {
            spacing: 20
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            Label {
                id: connectState
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Disconnected"
                font.pixelSize: 16
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
            }
            Label {
                id: timeElapsedLabel
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "00:00:00"
                font.pixelSize: 16
                horizontalAlignment: Qt.AlignRight
                verticalAlignment: Qt.AlignVCenter
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        GroupBox {
            height: 60
            padding: 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            RowLayout {
                anchors.fill: parent
                spacing: 10
                SpinBox {
                    id: timePeriod
                    value: 10
                    from: 1
                    to: 600
                    editable: true;
                    onValueChanged: core.timeSpan = value;
                    enabled: !core.running;
                    ToolTip.visible: hovered
                    ToolTip.timeout: 3000
                    ToolTip.text: qsTr("Time Period in Minutes")
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: "transparent"
                    Layout.fillHeight: true
                }

                ToolButton {
                    id: loadButton
                    display: AbstractButton.IconOnly
                    icon.source: "qrc:/images/icon_folder.png"
                    icon.color: Material.color(Material.BlueGrey)
                    enabled: !core.running;
                    ToolTip.visible: hovered
                    ToolTip.timeout: 3000
                    ToolTip.text: qsTr("Select File containing server list")
                    onClicked: fileDialog.open()
                }

                ToolButton {
                    id: connectButton
                    highlighted: true
                    display: AbstractButton.IconOnly
                    icon.source: "qrc:/images/icon_connect.png"
                    icon.color: Material.color(Material.BlueGrey)
                    ToolTip.visible: hovered
                    ToolTip.timeout: 3000
                    ToolTip.text: core.running? qsTr("Disconnect") : qsTr("Connect")
                    onClicked: {
                        if(core.running)
                            core.disconnectServer();
                        else
                            core.connectServer()
                    }
                }
            }

        }

        ListView {
            id: listView
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            model: serverList
            currentIndex: core.serverIndex
            delegate: ItemDelegate{
                width: listView.width
                highlighted: ListView.isCurrentItem
                Column {
                    anchors.fill: parent
                    anchors.margins: 5
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    Text {
                        text: model.name
                        width: parent.width
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        font.pointSize: 10
                        minimumPointSize: 4
                        fontSizeMode: Text.Fit
                        font.capitalization: Font.AllUppercase
                        wrapMode: Text.WordWrap
                        color: Material.color(Material.BlueGrey)
                    }

                    Text {
                        text: model.ip + ":" +model.port
                        width: parent.width
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pointSize: 8
                        minimumPointSize: 4
                        fontSizeMode: Text.Fit
                        wrapMode: Text.WordWrap
                        color: Material.color(Material.BlueGrey)
                    }
                }
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollBar.vertical: ScrollBar {}
        }
    }


    ToastManager {
        id: toast
    }

    BusyIndicator {
        id: busy
        anchors.centerIn: parent
        visible: false
    }

    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        folder: shortcuts.home
        nameFilters: [ "CSV files (*.csv)" ]
        onAccepted: {
            var path = fileUrl.toString();
            // remove prefixed "file:///"
            path = path.replace(/^(file:\/{3})/,"");
            // unescape html codes like '%23' for '#'
            var cleanPath = decodeURIComponent(path);
            refreshList(cleanPath)
        }
    }

    Connections {
        target: core
        function onServerListChanged() {
            var sl = core.serverList;
            for (var i = 0; i < sl.length; i++) {
                serverList.append(sl[i]);
            }

            busy.visible = false;
        }
    }

    Connections {
        target: core
        function onStatus(state) {
            connectState.text = state;
        }
    }

    Connections {
        target: core
        function onRunningChanged() {
            if(core.running) {
                timeElapsed = 0;
                timer.start();
            } else {
                timeElapsed = 0;
                timer.stop();
            }
        }
    }

    Connections {
        target: core
        function onError(err) {
            toast.show(err, false);
        }
    }

    Component.onCompleted: {
        var sl = core.serverList;
        for (var i = 0; i < sl.length; i++) {
            serverList.append(sl[i]);
        }
        timePeriod.value = core.timeSpan
        busy.visible = false;
    }
}
