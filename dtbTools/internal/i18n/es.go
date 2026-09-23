package i18n

var Spanish = Language{
	Title:   "Herramienta de Selección DTB - Versión Go",
	Variant: "es",
	Common: CommonStrings{
		Exit:                 " Salir : ",
		SelectNumber:         "\nSeleccione el número: ",
		InvalidSelection:     "Selección inválida.",
		PleaseEnterNumber:    "Por favor, ingrese un número",
		PressEnterToContinue: "Presione Enter para continuar...",
		Back:                 "Volver",
		GoodBye:              "¡Adiós!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "Selector DTB - Seleccione Su Consola",
		Welcome:           "\n================ Bienvenido ================",
		NoteInfo1:         "NOTA:\n• Este sistema actualmente solo admite los clones R36 listados;\n  si su clone no está en la lista, aún no es compatible.",
		NoteInfo2:         "💡 Si no sabe qué clone es su dispositivo, use https://lcdyk0517.github.io/dtbTools.html para ayudar a identificarlo",
		NoteInfo3:         "• NO use los archivos dtb de la tarjeta EmuELEC original con este sistema — arruinará el arranque.",

		BeforeSelectingConsole: "Antes de seleccionar una consola:",
		SubInfo:                "  luego copia la consola elegida y cualquier fuente extra mapeada.",
		Continue1:              "  • Presione Enter para continuar; escriba 'q' para salir.",
		Continue2:              "\nPresione Enter para continuar, Presione ",
		CancelledBye:           "Cancelado, ¡adiós! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Por favor, seleccione una marca",
		SearchOption:      "Buscar por palabra clave del modelo",
		SearchPrompt:      "Ingrese palabra clave del modelo (ej: r36s, rgb10max, 35h). Vacío = volver: ",
		SearchResultsFmt:  "Resultados de búsqueda para: \"%s\"",
		SearchNoResults:   "No se encontraron consolas coincidentes. Intente con una palabra clave diferente.",
		SearchHint:        "Consejo: ¿No sabe qué marca es su dispositivo? Elija Buscar y simplemente escriba el nombre del modelo.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Consolas disponibles para: ",
		NoConsolesFound:        "No se encontraron consolas.",
		Copying:                "Copiando: ",
		CopyingExtra:           "Copiando recursos extra...",
		CopyingFmt:             "  Copiando: %s\n",
		SelectBatteryVersion:   "Seleccione la versión del controlador de batería:",
		BatteryVersionOriginal: "1. controlador original de arkos (este controlador debe usarse junto con batteryplus; de lo contrario, el nivel de batería se mostrará anormalmente durante la carga).",
		BatteryVersionFix:      "2. controlador de batería arkos4clone (capaz de mostrar correctamente el nivel de batería tanto durante la carga como durante la descarga, y con una función de adaptación al envejecimiento)",
		CloneR36sNote: "NOTA:\n" +
			"• 'Con Amplificador' y 'Sin Amplificador' solo difieren en la salida de audio.\n" +
			"  Si uno no tiene sonido, pruebe el otro.\n" +
			"• Si la dirección arriba/abajo del joystick derecho está invertida en el DTB predeterminado,\n" +
			"  use la opción con 'Invert Right Joystick' en el nombre para corregirlo.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  ¡Operación completada!",
		ModelsCopied:         "Modelos que han sido copiados： ",
		Tip1:                 "  Consejo: Verifique los archivos en el directorio de destino.",
		CleanTargetDir:       "Limpiando directorio de destino...",
		DeleteFileFmt:        "  Eliminar archivo: %s\n",
		DeletionFailedFmt:    "    Advertencia: Error al eliminar %s: %v\n",
		DeleteDirectoryFmt:   "  Eliminar directorio: %s\n",
		DirDeletionFailedFmt: "    Advertencia: Error al eliminar el directorio %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Seleccione el idioma:",
		DefaultEnglish:    "  1. English (Predeterminado)",
		Info1:             "Ingrese el número o presione Enter. English es la selección predeterminada: ",
		TagFileCreated:    "Archivo de etiqueta de idioma chino creado. (.cn creado)",
		OperationComplete: "¡Operación completada! Idioma seleccionado: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "¿Desea ajustar los parámetros de overclocking?",
		OverclockTitle:       "Configuración de Parámetros de Overclocking",
		MaxFreqLabel:         "Frecuencia máxima (visible en ES después del arranque)",
		BootFreqLabel:        "Frecuencia de arranque (usada durante el inicio del sistema)",
		BootFreqMustLE:       "La frecuencia de arranque debe ser <= frecuencia máxima",
		DefaultFreqNote:      "Las frecuencias predeterminadas garantizan un arranque normal. Frecuencias por encima del predeterminado mostradas en ROJO.",
		RedWarning:           "ADVERTENCIA: ¡Exceder la frecuencia predeterminada puede causar bloqueos del sistema!",
		FreezeWarning:        "Si el sistema se bloquea, por favor disminuya la frecuencia.",
		CurrentConfig:        "Configuración actual:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Máx",
		BootFreq:             "Arr",
		ApplyOverclock:       "Aplicando parámetros de overclocking a boot.ini...",
		OverclockApplied:     "¡Parámetros de overclocking aplicados con éxito!",
		UsingDefaults:        "Usando parámetros de overclocking predeterminados (1296/520/666).",
		DDRCloneDefault:      "Predeterminado clon",
		DDROriginalDefault:   "Predeterminado original",
		OCWarning: "ADVERTENCIA: En este modo, NO envíe issues por ningún bug.\n" +
			"  Cualquier daño a la CPU es bajo su propio riesgo.\n" +
			"  Si no entiende esto, por favor seleccione N.\n" +
			"\n" +
			"  Por cierto, este sistema NO dañará sus altavoces.\n" +
			"  Si le preocupa ese riesgo, no lo use.\n" +
			"  No tenemos idea de por qué se propagan rumores tan ridículos.",
		GPUDDRFreezeTip:      "Si el sistema se bloquea después de entrar, disminuya la frecuencia.",
		AskVoltage:           "¿Desea aumentar el voltaje para mayor estabilidad?",
		VoltageTitle:         "Configuración de Aumento de Voltaje",
		VoltageWarning:       "ADVERTENCIA: ¡Aumentar el voltaje puede causar daños al hardware!",
		VoltageConfirmPrompt: "Para confirmar que entiende los riesgos, escriba: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Ingrese confirmación: ",
		VoltageWrongInput:    "Entrada incorrecta. Aumento de voltaje cancelado.",
		VoltageApplied:       "¡Aumento de voltaje aplicado con éxito!",
		VoltageSkipped:       "Aumento de voltaje omitido.",
	},
}
