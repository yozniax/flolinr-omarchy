pragma Singleton
import QtQuick
import "Translations.js" as Catalog

QtObject {
    property string language: "en"
    readonly property var languages: Catalog.languages
    readonly property var locale: Qt.locale(Catalog.localeName(language))
    function t(source, args) { return Catalog.translate(language, source, args); }
}
