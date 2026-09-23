package i18n

var Swedish = Language{
	Title:   "DTB Väljare - Go Version",
	Variant: "sv",
	Common: CommonStrings{
		Exit:                 " Avsluta : ",
		SelectNumber:         "\nVälj nummer: ",
		InvalidSelection:     "Ogiltigt val.",
		PleaseEnterNumber:    "Ange ett nummer",
		PressEnterToContinue: "Tryck Enter för att fortsätta...",
		Back:                 "Tillbaka",
		GoodBye:              "Hej då!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB Väljare - Välj Din Konsol",
		Welcome:           "\n================ Välkommen ================",
		NoteInfo1:         "OBS:\n• Detta system stöder för närvarande endast de listade R36-klonerna;\n  om din klon inte finns i listan stöds den inte ännu.",
		NoteInfo2:         "💡 Om du inte vet vilken klon din enhet är, använd https://lcdyk0517.github.io/dtbTools.html för att hjälpa att identifiera den",
		NoteInfo3:         "• Använd INTE dtb-filer från originalet EmuELEC-kort med detta system - det kommer att blockera uppstarten.",

		BeforeSelectingConsole: "Innan du väljer en konsol:",
		SubInfo:                "  kopierar sedan den valda konsolen och alla mappade extra källor.",
		Continue1:              "  • Tryck Enter för att fortsätta; skriv 'q' för att avsluta.",
		Continue2:              "\nTryck Enter för att fortsätta, Tryck ",
		CancelledBye:           "Avbruten, hej! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Välj ett märke",
		SearchOption:      "Sök efter modellnyckelord",
		SearchPrompt:      "Ange modellnyckelord (t.ex. r36s, rgb10max, 35h). Tomt = tillbaka: ",
		SearchResultsFmt:  "Sökresultat för: \"%s\"",
		SearchNoResults:   "Inga matchande konsoler hittades. Försök med ett annat nyckelord.",
		SearchHint:        "Tips: Vet du inte vilket märke din enhet är? Välj Sök och skriv bara in modellnamnet.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Tillgängliga konsoler för: ",
		NoConsolesFound:        "Inga konsoler hittades.",
		Copying:                "Kopierar: ",
		CopyingExtra:           "Kopierar extra resurser...",
		CopyingFmt:             "  Kopierar: %s\n",
		SelectBatteryVersion:   "Välj batteridrivrutinsversion:",
		BatteryVersionOriginal: "1. arkos originaldrivrutin (denna drivrutin måste användas tillsammans med batteryplus; annars kommer batterinivån att visas onormalt under laddning).",
		BatteryVersionFix:      "2. arkos4clone batteridrivrutin (kan korrekt visa batterinivån både under laddning och urladdning, och med en åldringsanpassningsfunktion)",
		CloneR36sNote: "OBS:\n" +
			"• 'Med Förstärkare' och 'Utan Förstärkare' skiljer sig endast i ljudutgång.\n" +
			"  Om den ena inte har ljud, prova den andra.\n" +
			"• Om den högre/ända riktningen på den högra joysticken är inverterad i standard-DTB,\n" +
			"  använd alternativet med 'Invert Right Joystick' i namnet för att fixa det.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Operation slutförd!",
		ModelsCopied:         "Kopierade modeller： ",
		Tip1:                 "  Tips: Verifiera filerna i målkatalogen.",
		CleanTargetDir:       "Rensar målkatalog...",
		DeleteFileFmt:        "  Ta bort fil: %s\n",
		DeletionFailedFmt:    "    Varning: Borttagning misslyckades %s: %v\n",
		DeleteDirectoryFmt:   "  Ta bort katalog: %s\n",
		DirDeletionFailedFmt: "    Varning: Borttagning av katalog misslyckades %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Välj språk:",
		DefaultEnglish:    "  1. English (Standard)",
		Info1:             "Ange nummer eller tryck Enter. English är standardvalet: ",
		TagFileCreated:    "Kinesiskt språktaggfil skapat. (.cn skapat)",
		OperationComplete: "Operation slutförd! Valt språk: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Vill du justera överklockningsparametrar?",
		OverclockTitle:       "Överklockningsparameterkonfiguration",
		MaxFreqLabel:         "Maximal frekvens (synlig i ES efter uppstart)",
		BootFreqLabel:        "Startfrekvens (används under systemstart)",
		BootFreqMustLE:       "Startfrekvens måste vara <= maxfrekvens",
		DefaultFreqNote:      "Standardfrekvenser garanterar normal uppstart. Frekvenser över standard visas i RÖTT.",
		RedWarning:           "VARNING: Överskridande av standardfrekvens kan orsaka systemfryst!",
		FreezeWarning:        "Om systemet fryser, sänk frekvensen.",
		CurrentConfig:        "Nuvarande konfiguration:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Max",
		BootFreq:             "Boot",
		ApplyOverclock:       "Tillämpar överklockningsparametrar på boot.ini...",
		OverclockApplied:     "Överklockningsparametrar tillämpade framgångsrikt!",
		UsingDefaults:        "Använder standardöverklockningsparametrar (1296/520/666).",
		DDRCloneDefault:      "Klondstandard",
		DDROriginalDefault:   "Originalstandard",
		OCWarning: "VARNING: I detta läge, skicka INTE issues för några bugs.\n" +
			"  All CPU-skada är på egen risk.\n" +
			"  Om du inte förstår detta, välj N.\n" +
			"\n" +
			"  Förresten, detta system kommer INTE att skada dina högtalare.\n" +
			"  Om du är orolig för denna risk, använd det inte.\n" +
			"  Vi har ingen aning om varför sådana löjliga rykten sprider sig.",
		GPUDDRFreezeTip:      "Om systemet fryser efter inmatning, sänk frekvensen.",
		AskVoltage:           "Vill du öka spänningen för högre stabilitet?",
		VoltageTitle:         "Spänningshöjningskonfiguration",
		VoltageWarning:       "VARNING: Ökning av spänningen kan orsaka hårdvaruskador!",
		VoltageConfirmPrompt: "För att bekräfta att du förstår riskerna, skriv: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Ange bekräftelse: ",
		VoltageWrongInput:    "Felaktig inmatning. Spänningsökning avbruten.",
		VoltageApplied:       "Spänningsökning tillämpad framgångsrikt!",
		VoltageSkipped:       "Spänningsökning överhoppad.",
	},
}
