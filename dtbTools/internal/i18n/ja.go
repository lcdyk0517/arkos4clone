package i18n

var Japanese = Language{
	Title:   "DTBセレクターツール - Go版",
	Variant: "ja",
	Common: CommonStrings{
		Exit:                 " 終了：",
		SelectNumber:         "\n番号を選択: ",
		InvalidSelection:     "無効な選択です。",
		PleaseEnterNumber:    "数字を入力してください",
		PressEnterToContinue: "Enterキーを押して続行...",
		Back:                 "戻る",
		GoodBye:              "さようなら！",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTBセレクター - コンソールを選択",
		Welcome:           "\n================ ようこそ ================",
		NoteInfo1:         "注記:\n• このシステムは現在、リストされているR36クローンのみをサポートしています;\n  お使いのクローンがリストにない場合は、まだサポートされていません。",
		NoteInfo2:         "💡 お使いのデバイスがどのクローンかわからない場合は、https://lcdyk0517.github.io/dtbTools.html を使用して識別してください",
		NoteInfo3:         "• このシステムで元のEmuELECカードのdtbファイルを使用しないでください - ブートがブロックされます。",

		BeforeSelectingConsole: "コンソールを選択する前:",
		SubInfo:                "  選択したコンソールとマッピングされた追加ソースをコピーします。",
		Continue1:              "  • Enterキーを押して続行; 'q'を入力して終了。",
		Continue2:              "\nEnterキーを押して続行、押す ",
		CancelledBye:           "キャンセルされました、さようなら！ 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ ブランドを選択してください",
		SearchOption:      "モデルキーワードで検索",
		SearchPrompt:      "モデルキーワードを入力 (例: r36s, rgb10max, 35h)。空欄 = 戻る: ",
		SearchResultsFmt:  "検索結果: \"%s\"",
		SearchNoResults:   "一致するコンソールが見つかりませんでした。別のキーワードを試してください。",
		SearchHint:        "ヒント: お使いのデバイスのブランドがわからないですか？検索を選択してモデル名を入力してください。",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "利用可能なコンソール: ",
		NoConsolesFound:        "コンソールが見つかりませんでした。",
		Copying:                "コピー中: ",
		CopyingExtra:           "追加リソースをコピー中...",
		CopyingFmt:             "  コピー中: %s\n",
		SelectBatteryVersion:   "バッテリドライババージョンを選択:",
		BatteryVersionOriginal: "1. arkosオリジナルドライバ (このドライバはbatteryplusと一緒に使用する必要があります。そうしないと、充電中にバッテリーレベルが異常に表示されます)。",
		BatteryVersionFix:      "2. arkos4cloneバッテリードライバ (充電と放電の両方でバッテリーレベルを正しく表示でき、エージング適応機能を備えています)",
		CloneR36sNote: "注記:\n" +
			"• 'アンプあり'と'アンプなし'はオーディオ出力のみが異なります。\n" +
			"  一方に音がない場合は、もう一方を試してください。\n" +
			"• デフォルトDTBで右ジョイスティックの上下方向が反転している場合、\n" +
			"  名前に'Invert Right Joystick'を含むオプションを使用して修正してください。",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  操作完了！",
		ModelsCopied:         "コピーされたモデル： ",
		Tip1:                 "  ヒント: 宛先ディレクトリのファイルを確認してください。",
		CleanTargetDir:       "宛先ディレクトリをクリーンアップ...",
		DeleteFileFmt:        "  ファイル削除: %s\n",
		DeletionFailedFmt:    "    警告: 削除に失敗しました %s: %v\n",
		DeleteDirectoryFmt:   "  ディレクトリ削除: %s\n",
		DirDeletionFailedFmt: "    警告: ディレクトリの削除に失敗しました %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "言語を選択:",
		DefaultEnglish:    "  1. English (デフォルト)",
		Info1:             "番号を入力するかEnterキーを押してください。Englishがデフォルトの選択です: ",
		TagFileCreated:    "中国語言語タグファイルが作成されました。(.cn created)",
		OperationComplete: "操作完了！選択された言語: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "オーバークロックパラメータを調整しますか？",
		OverclockTitle:       "オーバークロックパラメータ設定",
		MaxFreqLabel:         "最大周波数 (起動後にESで表示される最大周波数)",
		BootFreqLabel:        "起動周波数 (システム起動時に使用される周波数)",
		BootFreqMustLE:       "起動周波数は最大周波数以下である必要があります",
		DefaultFreqNote:      "デフォルト周波数は正常な起動を保証します。デフォルトを超える周波数は赤色で表示されます。",
		RedWarning:           "警告: デフォルト周波数を超えるとシステムがフリーズする可能性があります！",
		FreezeWarning:        "システムがフリーズした場合は、周波数を下げてください。",
		CurrentConfig:        "現在の設定:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "メモリ",
		MaxFreq:              "最大",
		BootFreq:             "起動",
		ApplyOverclock:       "オーバークロックパラメータをboot.iniに適用中...",
		OverclockApplied:     "オーバークロックパラメータが正常に適用されました！",
		UsingDefaults:        "デフォルトのオーバークロックパラメータを使用 (1296/520/666)。",
		DDRCloneDefault:      "クローンデフォルト",
		DDROriginalDefault:   "オリジナルデフォルト",
		OCWarning: "警告: このモードではバグに対してissuesを提出しないでください。\n" +
			"  CPUの損傷は自己責任です。\n" +
			"  これを理解していない場合はNを選択してください。\n" +
			"\n" +
			"  ちなみに、このシステムはスピーカーを破損させることはありません。\n" +
			"  このリスクが心配な場合は使用しないでください。\n" +
			"  なぜこのようなばかげた噂が広がるのか見当もつきません。",
		GPUDDRFreezeTip:      "システムに入った後にフリーズした場合は、周波数を下げてください。",
		AskVoltage:           "安定性を高めるために電圧を上げますか？",
		VoltageTitle:         "電圧増加設定",
		VoltageWarning:       "警告: 電圧を上げるとハードウェアが損傷する可能性があります！",
		VoltageConfirmPrompt: "リスクを理解したことを確認するには、入力してください: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "確認を入力: ",
		VoltageWrongInput:    "入力が正しくありません。電圧増加がキャンセルされました。",
		VoltageApplied:       "電圧増加が正常に適用されました！",
		VoltageSkipped:       "電圧増加をスキップしました。",
	},
}
