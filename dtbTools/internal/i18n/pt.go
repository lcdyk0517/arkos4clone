package i18n

var Portuguese = Language{
	Title:   "Ferramenta de Seleção DTB - Versão Go",
	Variant: "pt",
	Common: CommonStrings{
		UpdateAvailable:      "Nova versão disponível",
		Exit:                 " Sair : ",
		SelectNumber:         "\nSelecione o número: ",
		InvalidSelection:     "Seleção inválida.",
		PleaseEnterNumber:    "Por favor, insira um número",
		PressEnterToContinue: "Pressione Enter para continuar...",
		Back:                 "Voltar",
		GoodBye:              "Adeus!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "Seletor DTB - Selecione Seu Console",
		Welcome:           "\n================ Bem-vindo ================",
		NoteInfo1:         "NOTA:\n• Este sistema atualmente suporta apenas os clones R36 listados;\n  se o seu clone não estiver na lista, ainda não é suportado.",
		NoteInfo2:         "💡 Se você não sabe qual clone é o seu dispositivo, use https://lcdyk0517.github.io/dtbTools.html para ajudar a identificar",
		NoteInfo3:         "• NÃO use os arquivos dtb do cartão EmuELEC original com este sistema — irá bloquear o boot.",

		BeforeSelectingConsole: "Antes de selecionar uma consola:",
		SubInfo:                "  depois copia a consola escolhida e quaisquer fontes extras mapeadas.",
		Continue1:              "  • Pressione Enter para continuar; digite 'q' para sair.",
		Continue2:              "\nPressione Enter para continuar, Pressione ",
		CancelledBye:           "Cancelado, adeus! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Por favor, selecione uma marca",
		SearchOption:      "Pesquisar por palavra-chave do modelo",
		SearchPrompt:      "Digite a palavra-chave do modelo (ex: r36s, rgb10max, 35h). Vazio = voltar: ",
		SearchResultsFmt:  "Resultados da pesquisa para: \"%s\"",
		SearchNoResults:   "Nenhuma console correspondente encontrada. Tente uma palavra-chave diferente.",
		SearchHint:        "Dica: Não sabe qual marca é o seu dispositivo? Escolha Pesquisar e apenas digite o nome do modelo.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Consoles disponíveis para: ",
		NoConsolesFound:        "Nenhuma console encontrada.",
		Copying:                "Copiando: ",
		CopyingExtra:           "Copiando recursos extras...",
		CopyingFmt:             "  Copiando: %s\n",
		SelectBatteryVersion:   "Selecione a versão do driver de bateria:",
		BatteryVersionOriginal: "1. driver original arkos (este driver deve ser usado junto com batteryplus; caso contrário, o nível da bateria será exibido anormalmente durante o carregamento).",
		BatteryVersionFix:      "2. driver de bateria arkos4clone (capaz de exibir corretamente o nível da bateria durante o carregamento e a descarga, e com função de adaptação ao envelhecimento)",
		CloneR36sNote: "NOTA:\n" +
			"• 'Com Amplificador' e 'Sem Amplificador' diferem apenas na saída de áudio.\n" +
			"  Se um não tiver som, tente o outro.\n" +
			"• Se a direção cima/baixo do joystick direito estiver invertida no DTB padrão,\n" +
			"  use a opção com 'Invert Right Joystick' no nome para corrigir.",
		SoySauceNote: "NOTA:\n" +
			"• Para R36S da série Y3506, escolha estritamente conforme o resultado de deteção do webTools.\n" +
			"• Se perdeu o dtb original, teste-os um por um.\n" +
			"• A serigrafia da placa não revela o painel; os dispositivos SoySauce têm painéis muito misturados.\n" +
			"• Sem o dtb original, mesmo que um dtb SoySauce acenda o ecrã, NÃO significa que o seu aparelho use esse painel.\n" +
			"• Se o sistema arranca mas o ecrã fica preto ao sair de um jogo, mude de opção e continue a testar.",
		GameConsoleNote: "NOTA:\n" +
			"• O Panel 4 Type 1 e o Panel 4 Type 2 servem principalmente para distinguir se o Wi-Fi funciona.\n" +
			"• Se o Wi-Fi não funcionar no Panel 4 Type 1, mude para o Panel 4 Type 2, e vice-versa.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Operação concluída!",
		ModelsCopied:         "Modelos que foram copiados： ",
		Tip1:                 "  Dica: Verifique os arquivos no diretório de destino.",
		CleanTargetDir:       "Limpando diretório de destino...",
		DeleteFileFmt:        "  Excluir arquivo: %s\n",
		DeletionFailedFmt:    "    Aviso: Falha na exclusão %s: %v\n",
		DeleteDirectoryFmt:   "  Excluir diretório: %s\n",
		DirDeletionFailedFmt: "    Aviso: Falha na exclusão do diretório %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Selecione o idioma:",
		DefaultEnglish:    "  1. English (Padrão)",
		Info1:             "Digite o número ou pressione Enter. English é a seleção padrão: ",
		TagFileCreated:    "Arquivo de idioma chinês criado. (.cn criado)",
		OperationComplete: "Operação completa! Idioma selecionado: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:       "Deseja ajustar os parâmetros de overclocking?",
		OverclockTitle:     "Configuração de Parâmetros de Overclocking",
		MaxFreqLabel:       "Frequência máxima (visível no ES após a inicialização)",
		BootFreqLabel:      "Frequência de inicialização (usada durante a inicialização do sistema)",
		BootFreqMustLE:     "A frequência de inicialização deve ser <= frequência máxima",
		DefaultFreqNote:    "Frequências padrão garantem inicialização normal. Frequências acima do padrão mostradas em VERMELHO.",
		RedWarning:         "AVISO: Exceder a frequência padrão pode causar congelamento do sistema!",
		FreezeWarning:      "Se o sistema travar, por favor diminua a frequência.",
		CurrentConfig:      "Configuração atual:",
		ConfigCPU:          "CPU",
		ConfigGPU:          "GPU",
		ConfigDDR:          "DDR",
		MaxFreq:            "Max",
		BootFreq:           "Boot",
		ApplyOverclock:     "Aplicando parâmetros de overclocking ao boot.ini...",
		OverclockApplied:   "Parâmetros de overclocking aplicados com sucesso!",
		UsingDefaults:      "Usando parâmetros de overclocking padrão (1296/520/666).",
		DDRCloneDefault:    "Padrão clone",
		DDROriginalDefault: "Padrão original",
		OCWarning: "AVISO: Neste modo, NÃO envie issues para bugs.\n" +
			"  Qualquer dano à CPU é por sua conta e risco.\n" +
			"  Se não entender isso, por favor selecione N.\n" +
			"\n" +
			"  Ah, e por falar nisso, este sistema NÃO danificará suas caixas de som.\n" +
			"  Se está preocupado com esse risco, não o use.\n" +
			"  Não temos ideia de por que tais rumores ridículos se espalham.",
		GPUDDRFreezeTip:      "Se o sistema travar após entrar, diminua a frequência.",
		AskVoltage:           "Deseja aumentar a voltagem para maior estabilidade?",
		VoltageTitle:         "Configuração de Aumento de Voltagem",
		VoltageWarning:       "AVISO: Aumentar a voltagem pode causar danos ao hardware!",
		VoltageConfirmPrompt: "Para confirmar que entende os riscos, digite: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Digite a confirmação: ",
		VoltageWrongInput:    "Entrada incorreta. Aumento de voltagem cancelado.",
		VoltageApplied:       "Aumento de voltagem aplicado com sucesso!",
		VoltageSkipped:       "Aumento de voltagem ignorado.",
	},
	PortMaster: PortMasterStrings{
		Title:          "Dependências do PortMaster",
		AskExtract:     "Extrair as dependências do PortMaster para a partição Roms no primeiro arranque?\nSe o seu cartão SD for de má qualidade, escolha Não; caso contrário, a extração do roms.tar pode demorar demasiado.",
		KeepingLibs:    "As dependências do PortMaster serão extraídas para a Roms normalmente (sem alterações).",
		ExcludeApplied: "expandtoexfat.sh atualizado: os *.squashfs serão ignorados ao extrair o roms.tar.",
		ExcludeAlready: "expandtoexfat.sh já ignora os *.squashfs — sem alterações.",
	},
}
