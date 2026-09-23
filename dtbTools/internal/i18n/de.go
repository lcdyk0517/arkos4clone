package i18n

var German = Language{
	Title:   "DTB Auswahl-Tool - Go Version",
	Variant: "de",
	Common: CommonStrings{
		Exit:                 " Beenden : ",
		SelectNumber:         "\nNummer wählen: ",
		InvalidSelection:     "Ungültige Auswahl.",
		PleaseEnterNumber:    "Bitte geben Sie eine Zahl ein",
		PressEnterToContinue: "Drücken Sie Enter zum Fortfahren...",
		Back:                 "Zurück",
		GoodBye:              "Auf Wiedersehen!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB Selector - Wählen Sie Ihre Konsole",
		Welcome:           "\n================ Willkommen ================",
		NoteInfo1:         "HINWEIS:\n• Dieses System unterstützt derzeit nur die aufgelisteten R36-Klone;\n  wenn Ihr Klon nicht in der Liste steht, wird er noch nicht unterstützt.",
		NoteInfo2:         "💡 Wenn Sie nicht wissen, welchen Klon Ihr Gerät hat, verwenden Sie https://lcdyk0517.github.io/dtbTools.html zur Identifizierung",
		NoteInfo3:         "• Verwenden Sie KEINE dtb-Dateien von der Original-EmuELEC-Karte mit diesem System — es wird den Bootvorgang blockieren.",

		BeforeSelectingConsole: "Vor der Auswahl einer Konsole:",
		SubInfo:                "  dann kopiert es die gewählte Konsole und alle zugeordneten Extraquellen.",
		Continue1:              "  • Drücken Sie Enter zum Fortfahren; geben Sie 'q' zum Beenden ein.",
		Continue2:              "\nDrücken Sie Enter zum Fortfahren, Drücken ",
		CancelledBye:           "Abgebrochen, tschüss! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Bitte wählen Sie eine Marke",
		SearchOption:      "Nach Modell-Schlüsselwort suchen",
		SearchPrompt:      "Modell-Schlüsselwort eingeben (z.B. r36s, rgb10max, 35h). Leer = zurück: ",
		SearchResultsFmt:  "Suchergebnisse für: \"%s\"",
		SearchNoResults:   "Keine passenden Konsolen gefunden. Versuchen Sie ein anderes Schlüsselwort.",
		SearchHint:        "Tipp: Sie wissen nicht, welche Marke Ihr Gerät hat? Wählen Sie Suche und geben Sie einfach den Modellnamen ein.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Verfügbare Konsolen für: ",
		NoConsolesFound:        "Keine Konsolen gefunden.",
		Copying:                "Kopieren: ",
		CopyingExtra:           "Zusätzliche Ressourcen kopieren...",
		CopyingFmt:             "  Kopieren: %s\n",
		SelectBatteryVersion:   "Wählen Sie die Batterie-Treiberversion:",
		BatteryVersionOriginal: "1. arkos Original-Treiber (dieser Treiber muss zusammen mit batteryplus verwendet werden; andernfalls wird der Batteriestand während des Ladens abnormal angezeigt).",
		BatteryVersionFix:      "2. arkos4clone Batterie-Treiber (kann den Batteriestand sowohl beim Laden als auch beim Entladen korrekt anzeigen und verfügt über eine alterungsadaptive Funktion)",
		CloneR36sNote: "HINWEIS:\n" +
			"• 'Mit Verstärker' und 'Ohne Verstärker' unterscheiden sich nur im Audioausgang.\n" +
			"  Wenn eines keinen Ton hat, versuchen Sie das andere.\n" +
			"• Wenn die Auf/Ab-Richtung des rechten Joysticks im Standard-DTB invertiert ist,\n" +
			"  verwenden Sie die Option mit 'Invert Right Joystick' im Namen, um sie zu korrigieren.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Operation abgeschlossen!",
		ModelsCopied:         "Kopierte Modelle： ",
		Tip1:                 "  Tipp: Überprüfen Sie die Dateien im Zielverzeichnis.",
		CleanTargetDir:       "Zielverzeichnis bereinigen...",
		DeleteFileFmt:        "  Datei löschen: %s\n",
		DeletionFailedFmt:    "    Warnung: Löschen fehlgeschlagen %s: %v\n",
		DeleteDirectoryFmt:   "  Verzeichnis löschen: %s\n",
		DirDeletionFailedFmt: "    Warnung: Löschen des Verzeichnisses fehlgeschlagen %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Sprache auswählen:",
		DefaultEnglish:    "  1. English (Standard)",
		Info1:             "Nummer eingeben oder Enter drücken. English ist die Standardauswahl: ",
		TagFileCreated:    "Chinesische Sprach-Tag-Datei erstellt. (.cn erstellt)",
		OperationComplete: "Operation abgeschlossen! Sprache ausgewählt: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Möchten Sie die Übertaktungsparameter anpassen?",
		OverclockTitle:       "Übertaktungsparameter-Konfiguration",
		MaxFreqLabel:         "Maximale Frequenz (sichtbar in ES nach dem Booten)",
		BootFreqLabel:        "Boot-Frequenz (während des Systemstarts verwendet)",
		BootFreqMustLE:       "Boot-Frequenz muss <= Maximalfrequenz sein",
		DefaultFreqNote:      "Standardfrequenzen gewährleisten normalen Boot. Frequenzen über dem Standard werden in ROT angezeigt.",
		RedWarning:           "WARNUNG: Überschreiten der Standardfrequenz kann zu System-Freezes führen!",
		FreezeWarning:        "Wenn das System einfriert, senken Sie bitte die Frequenz.",
		CurrentConfig:        "Aktuelle Konfiguration:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Max",
		BootFreq:             "Boot",
		ApplyOverclock:       "Übertaktungsparameter auf boot.ini anwenden...",
		OverclockApplied:     "Übertaktungsparameter erfolgreich angewendet!",
		UsingDefaults:        "Standard-Übertaktungsparameter verwenden (1296/520/666).",
		DDRCloneDefault:      "Klone-Standard",
		DDROriginalDefault:   "Original-Standard",
		OCWarning: "WARNUNG: In diesem Modus senden Sie bitte KEINE Issues für Bugs.\n" +
			"  Jede CPU-Schädigung erfolgt auf eigene Gefahr.\n" +
			"  Wenn Sie dies nicht verstehen, wählen Sie bitte N.\n" +
			"\n" +
			"  Übrigens wird dieses System KEINE Lautsprecher beschädigen.\n" +
			"  Wenn Sie sich Sorgen über dieses Risiko machen, verwenden Sie es nicht.\n" +
			"  Wir haben keine Ahnung, warum sich solche lächerlichen Gerüchte verbreiten.",
		GPUDDRFreezeTip:      "Wenn das System nach dem Betreten einfriert, senken Sie die Frequenz.",
		AskVoltage:           "Möchten Sie die Spannung für höhere Stabilität erhöhen?",
		VoltageTitle:         "Spannungserhöhungs-Konfiguration",
		VoltageWarning:       "WARNUNG: Erhöhen der Spannung kann zu Hardwareschäden führen!",
		VoltageConfirmPrompt: "Um zu bestätigen, dass Sie die Risiken verstehen, tippen Sie: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Bestätigung eingeben: ",
		VoltageWrongInput:    "Falsche Eingabe. Spannungserhöhung abgebrochen.",
		VoltageApplied:       "Spannungserhöhung erfolgreich angewendet!",
		VoltageSkipped:       "Spannungserhöhung übersprungen.",
	},
}
