package i18n

var English = Language{
	Title:   "DTB Selector Tool - Go Version",
	Variant: "en",
	Common: CommonStrings{
		Exit:                 " Exit : ",
		SelectNumber:         "\nSelect number: ",
		InvalidSelection:     "Invalid selection.",
		PleaseEnterNumber:    "Please enter a number",
		PressEnterToContinue: "Press Enter to continue...",
		Back:                 "Back",
		GoodBye:              "Goodbye!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB Selector - Select Your Console",
		Welcome:           "\n================ Welcome ================",
		NoteInfo1:         "NOTE:\n• This system currently only supports the listed R36 clones;\n  if your clone is not in the list, it is not supported yet.",
		NoteInfo2:         "💡 If you don't know what clone your device is, use https://lcdyk0517.github.io/dtbTools.html to help identify it",
		NoteInfo3:         "• Do NOT use the dtb files from the stock EmuELEC card with this system — it will brick the boot.",

		BeforeSelectingConsole: "Before selecting a console:",
		SubInfo:                "  then copies the chosen console and any mapped extra sources.",
		Continue1:              "  • Press Enter to continue; type 'q' to quit.",
		Continue2:              "\nPress Enter to continue, Press ",
		CancelledBye:           "Cancelled, bye! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Please select a brand",
		SearchOption:      "Search by model keyword",
		SearchPrompt:      "Enter model keyword (e.g. r36s, rgb10max, 35h). Empty = back: ",
		SearchResultsFmt:  "Search results for: \"%s\"",
		SearchNoResults:   "No matching consoles found. Try a different keyword.",
		SearchHint:        "Tip: Don't know which brand your device is? Choose Search and just type the model name.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Available consoles for: ",
		NoConsolesFound:        "No consoles found.",
		Copying:                "Copying: ",
		CopyingExtra:           "Copying extra resources...",
		CopyingFmt:             "  Copying: %s\n",
		SelectBatteryVersion:   "Select battery driver version:",
		BatteryVersionOriginal: "1. arkos original driver (this driver must be used together with batteryplus; otherwise, the battery level will display abnormally during charging).",
		BatteryVersionFix:      "2. arkos4clone battery driver (capable of correctly displaying battery level during both charging and discharging, and featuring an aging‑adaptive function)",
		CloneR36sNote: "NOTE:\n" +
			"• 'With Amplifier' and 'Without Amplifier' differ only in audio output.\n" +
			"  If one has no sound, try the other.\n" +
			"• If the right joystick's up/down direction is inverted in the default DTB,\n" +
			"  use the option with 'Invert Right Joystick' in its name to fix it.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Operation completed!",
		ModelsCopied:         "Models that have been copied： ",
		Tip1:                 "  Tip: verify files in the destination directory.",
		CleanTargetDir:       "Cleaning target directory...",
		DeleteFileFmt:        "  Delete file: %s\n",
		DeletionFailedFmt:    "    Warning: Deletion failed %s: %v\n",
		DeleteDirectoryFmt:   "  Delete directory: %s\n",
		DirDeletionFailedFmt: "    Warning: Directory deletion failed %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Select language:",
		DefaultEnglish:    "  1. English (Default)",
		Info1:             "Enter the number or press Enter. English is the default selection: ",
		TagFileCreated:    "Chinese language tag file has been created. (.cn created)",
		OperationComplete: "Operation complete! Language selected: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Do you want to adjust overclocking parameters?",
		OverclockTitle:       "Overclocking Parameters Configuration",
		MaxFreqLabel:         "Maximum frequency (visible in ES after boot)",
		BootFreqLabel:        "Boot frequency (used during system startup)",
		BootFreqMustLE:       "Boot frequency must be <= max frequency",
		DefaultFreqNote:      "Default frequencies ensure normal boot. Frequencies above default shown in RED.",
		RedWarning:           "WARNING: Exceeding default frequency may cause system freeze!",
		FreezeWarning:        "If system freezes, please lower the frequency.",
		CurrentConfig:        "Current configuration:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Max",
		BootFreq:             "Boot",
		ApplyOverclock:       "Applying overclocking parameters to boot.ini...",
		OverclockApplied:     "Overclocking parameters applied successfully!",
		UsingDefaults:        "Using default overclocking parameters (1296/520/666).",
		DDRCloneDefault:      "Clone default",
		DDROriginalDefault:   "Original default",
		OCWarning: "WARNING: In this mode, do NOT submit issues for any bugs.\n" +
			"  Any CPU damage is at your own risk.\n" +
			"  If you don't understand this, please select N.\n" +
			"\n" +
			"  Oh by the way, this system will NOT damage your speakers.\n" +
			"  If you're worried about that risk, don't use it.\n" +
			"  We have no idea why such ridiculous rumors spread.",
		GPUDDRFreezeTip:      "If the system freezes after entering, please lower the frequency.",
		AskVoltage:           "Do you want to increase voltage for higher stability?",
		VoltageTitle:         "Voltage Increase Configuration",
		VoltageWarning:       "WARNING: Increasing voltage may cause hardware damage!",
		VoltageConfirmPrompt: "To confirm you understand the risks, type: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Enter confirmation: ",
		VoltageWrongInput:    "Incorrect input. Voltage increase cancelled.",
		VoltageApplied:       "Voltage increase applied successfully!",
		VoltageSkipped:       "Voltage increase skipped.",
	},
}
