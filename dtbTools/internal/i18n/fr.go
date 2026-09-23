package i18n

var French = Language{
	Title:   "Outil de Sélection DTB - Version Go",
	Variant: "fr",
	Common: CommonStrings{
		Exit:                 " Quitter : ",
		SelectNumber:         "\nSélectionnez le numéro: ",
		InvalidSelection:     "Sélection invalide.",
		PleaseEnterNumber:    "Veuillez entrer un nombre",
		PressEnterToContinue: "Appuyez sur Entrée pour continuer...",
		Back:                 "Retour",
		GoodBye:              "Au revoir!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "Sélecteur DTB - Sélectionnez Votre Console",
		Welcome:           "\n================ Bienvenue ================",
		NoteInfo1:         "NOTE:\n• Ce système prend actuellement en charge uniquement les clones R36 répertoriés;\n  si votre clone n'est pas dans la liste, il n'est pas encore pris en charge.",
		NoteInfo2:         "💡 Si vous ne savez pas quel clone est votre appareil, utilisez https://lcdyk0517.github.io/dtbTools.html pour aider à l'identifier",
		NoteInfo3:         "• N'utilisez PAS les fichiers dtb de la carte EmuELEC d'origine avec ce système — cela bloquera le démarrage.",

		BeforeSelectingConsole: "Avant de sélectionner une console:",
		SubInfo:                "  puis copie la console choisie et toutes les sources supplémentaires mappées.",
		Continue1:              "  • Appuyez sur Entrée pour continuer; tapez 'q' pour quitter.",
		Continue2:              "\nAppuyez sur Entrée pour continuer, Appuyez ",
		CancelledBye:           "Annulé, bye! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Veuillez sélectionner une marque",
		SearchOption:      "Rechercher par mot-clé du modèle",
		SearchPrompt:      "Entrez le mot-clé du modèle (ex: r36s, rgb10max, 35h). Vide = retour: ",
		SearchResultsFmt:  "Résultats de recherche pour: \"%s\"",
		SearchNoResults:   "Aucune console correspondante trouvée. Essayez un mot-clé différent.",
		SearchHint:        "Astuce: Vous ne savez pas quelle marque est votre appareil? Choisissez Rechercher et tapez simplement le nom du modèle.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Consoles disponibles pour: ",
		NoConsolesFound:        "Aucune console trouvée.",
		Copying:                "Copie: ",
		CopyingExtra:           "Copie de ressources supplémentaires...",
		CopyingFmt:             "  Copie: %s\n",
		SelectBatteryVersion:   "Sélectionnez la version du pilote de batterie:",
		BatteryVersionOriginal: "1. pilote original arkos (ce pilote doit être utilisé avec batteryplus; sinon, le niveau de batterie s'affichera anormalement pendant la charge).",
		BatteryVersionFix:      "2. pilote de batterie arkos4clone (capable d'afficher correctement le niveau de batterie pendant la charge et la décharge, et doté d'une fonction d'adaptation au vieillissement)",
		CloneR36sNote: "NOTE:\n" +
			"• 'Avec Amplificateur' et 'Sans Amplificateur' ne diffèrent que par la sortie audio.\n" +
			"  Si l'une n'a pas de son, essayez l'autre.\n" +
			"• Si la direction haut/bas du joystick droit est inversée dans le DTB par défaut,\n" +
			"  utilisez l'option avec 'Invert Right Joystick' dans le nom pour la corriger.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Opération terminée!",
		ModelsCopied:         "Modèles copiés： ",
		Tip1:                 "  Conseil: Vérifiez les fichiers dans le répertoire de destination.",
		CleanTargetDir:       "Nettoyage du répertoire de destination...",
		DeleteFileFmt:        "  Supprimer le fichier: %s\n",
		DeletionFailedFmt:    "    Avertissement: Échec de la suppression %s: %v\n",
		DeleteDirectoryFmt:   "  Supprimer le répertoire: %s\n",
		DirDeletionFailedFmt: "    Avertissement: Échec de la suppression du répertoire %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Sélectionnez la langue:",
		DefaultEnglish:    "  1. English (Par défaut)",
		Info1:             "Entrez le numéro ou appuyez sur Entrée. English est la sélection par défaut: ",
		TagFileCreated:    "Fichier de balise de langue chinoise créé. (.cn créé)",
		OperationComplete: "Opération terminée! Langue sélectionnée: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Voulez-vous ajuster les paramètres d'overclocking?",
		OverclockTitle:       "Configuration des Paramètres d'Overclocking",
		MaxFreqLabel:         "Fréquence maximale (visible dans ES après le démarrage)",
		BootFreqLabel:        "Fréquence de démarrage (utilisée pendant le démarrage du système)",
		BootFreqMustLE:       "La fréquence de démarrage doit être <= fréquence maximale",
		DefaultFreqNote:      "Les fréquences par défaut assurent un démarrage normal. Les fréquences supérieures à la valeur par défaut sont affichées en ROUGE.",
		RedWarning:           "AVERTISSEMENT: Dépasser la fréquence par défaut peut provoquer un gel du système!",
		FreezeWarning:        "Si le système se bloque, veuillez réduire la fréquence.",
		CurrentConfig:        "Configuration actuelle:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Max",
		BootFreq:             "Dém",
		ApplyOverclock:       "Application des paramètres d'overclocking à boot.ini...",
		OverclockApplied:     "Paramètres d'overclocking appliqués avec succès!",
		UsingDefaults:        "Utilisation des paramètres d'overclocking par défaut (1296/520/666).",
		DDRCloneDefault:      "Par défaut clone",
		DDROriginalDefault:   "Par défaut original",
		OCWarning: "AVERTISSEMENT: Dans ce mode, ne soumettez PAS de issues pour des bugs.\n" +
			"  Tout dommage au CPU est à vos propres risques.\n" +
			"  Si vous ne comprenez pas cela, veuillez sélectionner N.\n" +
			"\n" +
			"  Au fait, ce système NE ENDOMMAGERA PAS vos enceintes.\n" +
			"  Si vous craignez ce risque, ne l'utilisez pas.\n" +
			"  Nous n'avons aucune idée de pourquoi de telles rumeurs ridicules se propagent.",
		GPUDDRFreezeTip:      "Si le système se bloque après l'entrée, réduisez la fréquence.",
		AskVoltage:           "Voulez-vous augmenter la tension pour une meilleure stabilité?",
		VoltageTitle:         "Configuration d'Augmentation de Tension",
		VoltageWarning:       "AVERTISSEMENT: Augmenter la tension peut causer des dommages matériels!",
		VoltageConfirmPrompt: "Pour confirmer que vous comprenez les risques, tapez: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Entrez la confirmation: ",
		VoltageWrongInput:    "Entrée incorrecte. Augmentation de tension annulée.",
		VoltageApplied:       "Augmentation de tension appliquée avec succès!",
		VoltageSkipped:       "Augmentation de tension ignorée.",
	},
}
