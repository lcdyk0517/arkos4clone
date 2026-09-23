package i18n

var ChineseTraditional = Language{
	Title:   "DTB 選擇工具 - Go 版本",
	Variant: "zh-tw",
	Common: CommonStrings{
		Exit:                 " 退出：",
		SelectNumber:         "\n選擇序號: ",
		InvalidSelection:     "選擇無效，請重試.",
		PleaseEnterNumber:    "請輸入數字",
		PressEnterToContinue: "按 Enter 返回...",
		Back:                 "返回",
		GoodBye:              "再見！",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB 選擇器 - 請選擇機型",
		Welcome:           "\n================ 歡迎使用 ================",
		NoteInfo1:         "說明：\n本系統目前只支援下列機型，如果你的 R36 克隆機不在列表中，則暫時無法使用。",
		NoteInfo2:         "💡 如果你不知道你的設備是什麼克隆，可以使用 https://lcdyk0517.github.io/dtbTools.html 來輔助判斷",
		NoteInfo3:         "請不要使用原裝 EmuELEC 卡中的 dtb 檔案搭配本系統，否則會導致系統無法啟動！",

		BeforeSelectingConsole: "選擇機型前請閱讀：",
		SubInfo:                "  • 隨後複製所選機型及額外映射資源。",
		Continue1:              "  • 按 Enter 繼續；輸入 q 退出。",
		Continue2:              "\n按 Enter 繼續，或輸入 ",
		CancelledBye:           "已取消，拜拜 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ 請選擇品牌",
		SearchOption:      "按型號關鍵字搜尋",
		SearchPrompt:      "輸入型號關鍵字 (例如 r36s、rgb10max、35h)，直接回車返回: ",
		SearchResultsFmt:  "搜尋 \"%s\" 的結果: ",
		SearchNoResults:   "沒有找到匹配的機型，請換個關鍵字試試.",
		SearchHint:        "提示：不知道設備屬於哪個品牌？選擇搜尋，直接輸入型號即可。",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "該品牌可用機型: ",
		NoConsolesFound:        "該品牌下沒有機型.",
		Copying:                "開始複製: ",
		CopyingExtra:           "正在複製額外資源...",
		CopyingFmt:             "  開始複製: %s\n",
		SelectBatteryVersion:   "請選擇電池驅動版本:",
		BatteryVersionOriginal: "1. arkos 原始驅動（該驅動需要搭配batteryplus來使用否則會在充電時電量顯示異常）",
		BatteryVersionFix:      "2. arkos4clone 電池驅動（該版本驅動能够在充電和用電時正確顯示電池電量，並且具備老化自適應功能）",
		CloneR36sNote: "說明：\n" +
			"• 'With Amplifier' 和 'Without Amplifier' 僅在聲音輸出上有區別。\n" +
			"  如果其中一個沒有聲音，請嘗試另一個。\n" +
			"• 若默認 DTB 右搖桿上下顛倒，請使用名稱中帶 'Invert Right Joystick' 的版本修復。",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  操作完成！",
		ModelsCopied:         "已複製的機型： ",
		Tip1:                 "  提示：請檢查目標目錄確保檔案完整。",
		CleanTargetDir:       "開始清理目標目錄...",
		DeleteFileFmt:        "  刪除檔案: %s\n",
		DeletionFailedFmt:    "    警告: 刪除失敗 %s: %v\n",
		DeleteDirectoryFmt:   "  刪除目錄: %s\n",
		DirDeletionFailedFmt: "    警告: 刪除目錄失敗 %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "請選擇語言:",
		DefaultEnglish:    "  1. English (預設)",
		Info1:             "輸入序號或按 Enter 預設選擇 English: ",
		TagFileCreated:    "已建立中文語言標記檔案. (.cn created)",
		OperationComplete: "操作完成！已選擇語言: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "是否要調整超頻參數？",
		OverclockTitle:       "超頻參數配置",
		MaxFreqLabel:         "最大頻率（開機後可在ES中看到的頻率）",
		BootFreqLabel:        "啟動頻率（系統啟動時使用的頻率）",
		BootFreqMustLE:       "啟動頻率必須 <= 最大頻率",
		DefaultFreqNote:      "默認頻率保證正常開機。超過默認頻率的選項顯示為紅色。",
		RedWarning:           "警告：超過默認頻率可能導致系統卡死！",
		FreezeWarning:        "如果遇到卡死請降低頻率。",
		CurrentConfig:        "當前配置：",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "記憶體",
		MaxFreq:              "最大",
		BootFreq:             "啟動",
		ApplyOverclock:       "正在將超頻參數寫入 boot.ini...",
		OverclockApplied:     "超頻參數已成功套用！",
		UsingDefaults:        "使用默認超頻參數 (1296/520/666)。",
		DDRCloneDefault:      "克隆機默認",
		DDROriginalDefault:   "原版機默認",
		OCWarning: "警告：在此模式下出現任何bug請不要提交issues。\n" +
			"  導致CPU效能損壞請自行負責。\n" +
			"  如果你對此行為不了解請選擇N。\n" +
			"\n" +
			"  哦順便說一句，該系統不會導致揚聲器損壞。\n" +
			"  如果你擔心會有這種風險請不要使用。\n" +
			"  我也不知道這種離譜的謠言為什麼會被傳播，甚至有人相信。",
		GPUDDRFreezeTip:      "如果進入系統後遇到卡死請降低頻率。",
		AskVoltage:           "是否要增加電壓以提高穩定性？",
		VoltageTitle:         "電壓增加配置",
		VoltageWarning:       "警告：增加電壓可能導致硬體損壞！",
		VoltageConfirmPrompt: "請輸入以下內容確認您了解風險：",
		VoltageConfirmText:   "我知道我在做什麼",
		VoltageInputPrompt:   "請輸入確認文本：",
		VoltageWrongInput:    "輸入錯誤，已取消電壓增加。",
		VoltageApplied:       "電壓增加已成功套用！",
		VoltageSkipped:       "已跳過電壓增加。",
	},
}
