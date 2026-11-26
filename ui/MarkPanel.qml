pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui

Ui.KeyboardPanel {
    id: panel
    required property var host
    anchorItem: host.anchorButton
    owner: host
    bar: host.bar
    open: host.opened
    focusTarget: host.browsing ? list : field
    contentWidth: fittedContentWidth(Style.space(430))
    contentHeight: fittedContentHeight(column.implicitHeight)

    function focusPage() {
        if (open && focusTarget) focusTarget.forceActiveFocus()
    }

    function stamp(iso) {
        return new Date(iso).toLocaleString(Qt.locale(Commons.I18n.formatLocale), Locale.ShortFormat)
    }

    component Label: Text {
        textFormat: Text.PlainText
        color: Commons.Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
    }

    Column {
        id: column
        width: parent.width
        spacing: Style.space(8)
        Keys.onEscapePressed: panel.host.close()
        Label {
            width: parent.width
            font.bold: true
            font.pixelSize: Style.font.subtitle
            text: panel.host.words.t(panel.host.browsing ? "history" : "title")
        }
        Label {
            width: parent.width
            visible: !panel.host.browsing && !!panel.host.snapshot
            text: {
                var item = panel.host.snapshot
                if (!item) return ""
                var parts = [panel.stamp(item.recorded), item.app || panel.host.words.t("unknown")]
                if (item.workspace) parts.push(panel.host.words.t("workspace").arg(item.workspace))
                return parts.join(" · ")
            }
        }
        Ui.TextField {
            id: field
            width: parent.width
            visible: !panel.host.browsing
            enabled: !panel.host.saving
            maximumLength: 1600
            text: panel.host.note
            placeholderText: panel.host.words.t("note")
            onTextEdited: panel.host.note = text
            onAccepted: panel.host.save()
        }
        Row {
            visible: !panel.host.browsing
            spacing: Style.space(8)
            Ui.Button {
                text: panel.host.words.t("save")
                enabled: !!panel.host.snapshot && !panel.host.saving
                bordered: true
                focusable: true
                onClicked: panel.host.save()
            }
            Ui.Button {
                text: panel.host.words.t("history")
                enabled: !panel.host.saving && panel.host.note.length === 0
                focusable: true
                onClicked: panel.host.history()
            }
        }
        Label {
            visible: panel.host.browsing && !panel.host.failed
            width: parent.width
            text: panel.host.words.t(panel.host.listing ? "loading" : panel.host.marks.length ? "pick" : "empty")
        }
        Label {
            visible: panel.host.failed
            width: parent.width
            wrapMode: Text.Wrap
            text: panel.host.words.t("error")
        }
        Label {
            width: parent.width
            visible: panel.host.failed
            text: panel.host.words.t("error")
        }
        ListView {
            id: list
            width: parent.width
            visible: panel.host.browsing && count > 0
            height: visible ? Math.min(count, 5) * Style.space(53) : 0
            clip: true
            model: panel.host.marks
            keyNavigationEnabled: true
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
            Keys.onSpacePressed: if (currentItem) panel.host.selectMark(currentItem.modelData.id)
            Keys.onReturnPressed: panel.host.compare()
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: Style.space(53)
                color: list.activeFocus && ListView.isCurrentItem ? Style.focusFillFor(Commons.Color.popups.text, Commons.Color.accent) : "transparent"
                Label {
                    id: tick
                    x: Style.space(5)
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.host.selectedIds.includes(row.modelData.id) ? "☑" : "☐"
                }
                Column {
                    anchors.left: tick.right
                    anchors.leftMargin: Style.space(10)
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(14)
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        width: parent.width
                        text: row.modelData.note || panel.host.words.t("noNote")
                    }
                    Label {
                        width: parent.width
                        opacity: 0.75
                        text: panel.stamp(row.modelData.recorded) + " · " + (row.modelData.app || panel.host.words.t("unknown"))
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        list.currentIndex = row.index
                        list.forceActiveFocus()
                        panel.host.selectMark(row.modelData.id)
                    }
                }
            }
        }
        Ui.Button {
            visible: panel.host.browsing && panel.host.marks.length > 1
            enabled: panel.host.selectedIds.length >= 2
            bordered: true
            focusable: true
            text: panel.host.words.t("compare")
            onClicked: panel.host.compare()
        }
        Label {
            width: parent.width
            visible: panel.host.failed
            text: panel.host.words.t("error")
        }
    }
}
