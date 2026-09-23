package i18n

var Polish = Language{
	Title:   "Narzędzie Wyboru DTB - Wersja Go",
	Variant: "pl",
	Common: CommonStrings{
		Exit:                 " Wyjście : ",
		SelectNumber:         "\nWybierz numer: ",
		InvalidSelection:     "Nieprawidłowy wybór.",
		PleaseEnterNumber:    "Proszę podać liczbę",
		PressEnterToContinue: "Naciśnij Enter, aby kontynuować...",
		Back:                 "Powrót",
		GoodBye:              "Do widzenia!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "Selektor DTB - Wybierz Swoją Konsolę",
		Welcome:           "\n================ Witamy ================",
		NoteInfo1:         "UWAGA:\n• Ten system obsługuje obecnie tylko wymienione klony R36;\n  jeśli twój klon nie jest na liście, nie jest jeszcze obsługiwany.",
		NoteInfo2:         "💡 Jeśli nie wiesz, jaki klon jest twoim urządzeniem, użyj https://lcdyk0517.github.io/dtbTools.html aby pomóc go zidentyfikować",
		NoteInfo3:         "• NIE używaj plików dtb z oryginalnej karty EmuELEC z tym systemem - zablokuje on bootowanie.",

		BeforeSelectingConsole: "Przed wyborem konsoli:",
		SubInfo:                "  następnie kopiuje wybraną konsolę i wszystkie mapowane dodatkowe źródła.",
		Continue1:              "  • Naciśnij Enter, aby kontynuować; wpisz 'q', aby wyjść.",
		Continue2:              "\nNaciśnij Enter, aby kontynuować, Naciśnij ",
		CancelledBye:           "Anulowano, pa! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Proszę wybrać markę",
		SearchOption:      "Szukaj według słowa kluczowego modelu",
		SearchPrompt:      "Wpisz słowo kluczowe modelu (np. r36s, rgb10max, 35h). Puste = powrót: ",
		SearchResultsFmt:  "Wyniki wyszukiwania dla: \"%s\"",
		SearchNoResults:   "Nie znaleziono pasujących konsol. Spróbuj innego słowa kluczowego.",
		SearchHint:        "Wskazówka: Nie wiesz, jaka marka jest twoim urządzeniem? Wybierz Szukaj i po prostu wpisz nazwę modelu.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Dostępne konsole dla: ",
		NoConsolesFound:        "Nie znaleziono konsol.",
		Copying:                "Kopiowanie: ",
		CopyingExtra:           "Kopiowanie dodatkowych zasobów...",
		CopyingFmt:             "  Kopiowanie: %s\n",
		SelectBatteryVersion:   "Wybierz wersję sterownika baterii:",
		BatteryVersionOriginal: "1. oryginalny sterownik arkos (ten sterownik musi być używany razem z batteryplus; w przeciwnym razie poziom baterii będzie wyświetlany nieprawidłowo podczas ładowania).",
		BatteryVersionFix:      "2. sterownik baterii arkos4clone (zdolny do prawidłowego wyświetlania poziomu baterii zarówno podczas ładowania, jak i rozładowania, i z funkcją adaptacji do starzenia)",
		CloneR36sNote: "UWAGA:\n" +
			"• 'Z Wzmacniaczem' i 'Bez Wzmacniacza' różnią się tylko wyjściem audio.\n" +
			"  Jeśli jedno nie ma dźwięku, spróbuj drugie.\n" +
			"• Jeśli kierunek góra/dół prawego joysticka jest odwrócony w domyślnym DTB,\n" +
			"  użyj opcji z 'Invert Right Joystick' w nazwie, aby to naprawić.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Operacja zakończona!",
		ModelsCopied:         "Skopiowane modele： ",
		Tip1:                 "  Wskazówka: Sprawdź pliki w katalogu docelowym.",
		CleanTargetDir:       "Czyszczenie katalogu docelowego...",
		DeleteFileFmt:        "  Usuń plik: %s\n",
		DeletionFailedFmt:    "    Ostrzeżenie: Usuwanie nie powiodło się %s: %v\n",
		DeleteDirectoryFmt:   "  Usuń katalog: %s\n",
		DirDeletionFailedFmt: "    Ostrzeżenie: Usuwanie katalogu nie powiodło się %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Wybierz język:",
		DefaultEnglish:    "  1. English (Domyślny)",
		Info1:             "Wpisz numer lub naciśnij Enter. English jest domyślnym wyborem: ",
		TagFileCreated:    "Utworzono plik tagu języka chińskiego. (.cn utworzono)",
		OperationComplete: "Operacja zakończona! Wybrany język: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Czy chcesz dostosować parametry overclockingu?",
		OverclockTitle:       "Konfiguracja Parametrów Overclockingu",
		MaxFreqLabel:         "Maksymalna częstotliwość (widoczna w ES po starcie)",
		BootFreqLabel:        "Częstotliwość rozruchu (używana podczas uruchamiania systemu)",
		BootFreqMustLE:       "Częstotliwość rozruchu musi być <= maksymalna częstotliwość",
		DefaultFreqNote:      "Domyślne częstotliwości gwarantują normalny rozruch. Częstotliwości powyżej domyślnej wyświetlane na CZERWONO.",
		RedWarning:           "OSTRZEŻENIE: Przekroczenie domyślnej częstotliwości może spowodować zawieszenie systemu!",
		FreezeWarning:        "Jeśli system się zawiesi, zmniejsz częstotliwość.",
		CurrentConfig:        "Aktualna konfiguracja:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Maks",
		BootFreq:             "Rozr",
		ApplyOverclock:       "Stosowanie parametrów overclockingu do boot.ini...",
		OverclockApplied:     "Parametry overclockingu zastosowane pomyślnie!",
		UsingDefaults:        "Używanie domyślnych parametrów overclockingu (1296/520/666).",
		DDRCloneDefault:      "Domyślne klona",
		DDROriginalDefault:   "Domyślne oryginalne",
		OCWarning: "OSTRZEŻENIE: W tym modele NIE wysyłaj issues za jakiekolwiek błędy.\n" +
			"  Jakiekolwiek uszkodzenie CPU jest na własne ryzyko.\n" +
			"  Jeśli tego nie rozumiesz, wybierz N.\n" +
			"\n" +
			"  Oh, a tak między nami, ten system NIE zniszczy twoich głośników.\n" +
			"  Jeśli martwisz się o to ryzyko, nie używaj tego.\n" +
			"  Nie mamy pojęcia, dlaczego rozprzestrzeniają się takie absurdalne plotki.",
		GPUDDRFreezeTip:      "Jeśli system się zawiesi po wejściu, zmniejsz częstotliwość.",
		AskVoltage:           "Czy chcesz zwiększyć napięcie dla większej stabilności?",
		VoltageTitle:         "Konfiguracja Zwiększania Napięcia",
		VoltageWarning:       "OSTRZEŻENIE: Zwiększenie napięcia może spowodować uszkodzenie sprzętu!",
		VoltageConfirmPrompt: "Aby potwierdzić, że rozumiesz ryzyka, wpisz: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Wpisz potwierdzenie: ",
		VoltageWrongInput:    "Nieprawidłowe wejście. Zwiększenie napięcia anulowane.",
		VoltageApplied:       "Zwiększenie napięcia zastosowane pomyślnie!",
		VoltageSkipped:       "Zwiększenie napięcia pominięte.",
	},
}
