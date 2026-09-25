package i18n

var Chinese = Language{
	Title:   "DTB 选择工具 - Go 版本",
	Variant: "cn",
	Common: CommonStrings{
		Exit:                 " 退出：",
		SelectNumber:         "\n选择序号: ",
		InvalidSelection:     "选择无效，请重试.",
		PleaseEnterNumber:    "请输入数字",
		PressEnterToContinue: "按 Enter 返回...",
		Back:                 "返回",
		GoodBye:              "再见！",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB Selector - 请选择机型",
		Welcome:           "\n================ 欢迎使用 ================",
		NoteInfo1:         "说明：\n本系统目前只支持下列机型，如果你的 R36 克隆机不在列表中，则暂时无法使用。",
		NoteInfo2:         "💡 如果你不知道你的设备是什么克隆，可以使用 https://lcdyk0517.github.io/dtbTools.html 来辅助判断",
		NoteInfo3:         "请不要使用原装 EmuELEC 卡中的 dtb 文件搭配本系统，否则会导致系统无法启动！",

		BeforeSelectingConsole: "选择机型前请阅读：",
		SubInfo:                "  • 随后复制所选机型及额外映射资源。",
		Continue1:              "  • 按 Enter 继续；输入 q 退出。",
		Continue2:              "\n按 Enter 继续，或输入 ",
		CancelledBye:           "已取消，拜拜 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ 请选择品牌",
		SearchOption:      "按型号关键字搜索",
		SearchPrompt:      "输入型号关键字 (例如 r36s、rgb10max、35h)，直接回车返回: ",
		SearchResultsFmt:  "搜索 \"%s\" 的结果: ",
		SearchNoResults:   "没有找到匹配的机型，请换个关键字试试.",
		SearchHint:        "提示：不知道设备属于哪个品牌？选择搜索，直接输入型号即可。",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "该品牌可用机型: ",
		NoConsolesFound:        "该品牌下没有机型.",
		Copying:                "开始复制: ",
		CopyingExtra:           "正在复制额外资源...",
		CopyingFmt:             "  开始复制: %s\n",
		SelectBatteryVersion:   "请选择电池驱动版本:",
		BatteryVersionOriginal: "1. arkos 原始驱动（该驱动需要搭配batteryplus来使用否则会在充电时电量显示异常）",
		BatteryVersionFix:      "2. arkos4clone 电池驱动（该版本驱动能够在充电和用电时正确显示电池电量，并且具备老化自适应功能）",
		CloneR36sNote: "说明：\n" +
			"• 'With Amplifier' 和 'Without Amplifier' 仅在声音输出上有区别。\n" +
			"  如果其中一个没有声音，请尝试另一个。\n" +
			"• 若默认 DTB 右摇杆上下颠倒，请使用名称中带 'Invert Right Joystick' 的版本修复。",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  操作完成！",
		ModelsCopied:         "已复制的机型： ",
		Tip1:                 "  提示：请检查目标目录确保文件完整。",
		CleanTargetDir:       "开始清理目标目录...",
		DeleteFileFmt:        "  删除文件: %s\n",
		DeletionFailedFmt:    "    警告: 删除失败 %s: %v\n",
		DeleteDirectoryFmt:   "  删除目录: %s\n",
		DirDeletionFailedFmt: "    警告: 删除目录失败 %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "请选择语言:",
		DefaultEnglish:    "  1. 英文 (默认)",
		Info1:             "输入序号或按 Enter 默认选择 英文: ",
		TagFileCreated:    "已创建中文语言标记文件. (.cn created)",
		OperationComplete: "操作完成！已选择语言: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "是否要调整超频参数？",
		OverclockTitle:       "超频参数配置",
		MaxFreqLabel:         "最大频率（开机后可在ES中看到的最大频率）",
		BootFreqLabel:        "启动频率（系统启动时使用的频率）",
		BootFreqMustLE:       "启动频率必须 <= 最大频率",
		DefaultFreqNote:      "默认频率保证正常开机。超过默认频率的选项显示为红色。",
		RedWarning:           "警告：超过默认频率可能导致系统卡死！",
		FreezeWarning:        "如果遇到卡死请降低频率。",
		CurrentConfig:        "当前配置：",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "内存",
		MaxFreq:              "最大",
		BootFreq:             "启动",
		ApplyOverclock:       "正在将超频参数写入 boot.ini...",
		OverclockApplied:     "超频参数已成功应用！",
		UsingDefaults:        "使用默认超频参数 (1296/520/666)。",
		DDRCloneDefault:      "克隆机默认",
		DDROriginalDefault:   "original（原版机）默认",
		OCWarning: "警告：在此模式下出现任何bug请不要提交issues。\n" +
			"  导致CPU性能损坏请自行负责。\n" +
			"  如果你对此行为不了解请选择N。\n" +
			"\n" +
			"  哦顺便说一句，该系统不会导致扬声器损坏。\n" +
			"  如果你担心会有这种风险请不要使用。\n" +
			"  我也不知道这种离谱的谣言为什么会被传播，甚至有人相信。",
		GPUDDRFreezeTip:      "如果进入系统后遇到卡死请降低频率。",
		AskVoltage:           "是否要增加电压以提高稳定性？",
		VoltageTitle:         "电压增加配置",
		VoltageWarning:       "警告：增加电压可能导致硬件损坏！",
		VoltageConfirmPrompt: "请输入以下内容确认您了解风险：",
		VoltageConfirmText:   "我知道我在做什么",
		VoltageInputPrompt:   "请输入确认文本：",
		VoltageWrongInput:    "输入错误，已取消电压增加。",
		VoltageApplied:       "电压增加已成功应用！",
		VoltageSkipped:       "已跳过电压增加。",
	},
}
