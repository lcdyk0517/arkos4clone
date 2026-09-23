package i18n

var Korean = Language{
	Title:   "DTB 선택 도구 - Go 버전",
	Variant: "ko",
	Common: CommonStrings{
		Exit:                 " 종료：",
		SelectNumber:         "\n선택하세요: ",
		InvalidSelection:     "잘못된 선택이에요.",
		PleaseEnterNumber:    "숫자를 입력하세요",
		PressEnterToContinue: "Enter를 눌러주세요...",
		Back:                 "뒤로가기",
		GoodBye:              "빠이!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "DTB Selector - 콘솔을 선택하세요",
		Welcome:           "\n================ 방가방가 ================",
		NoteInfo1:         "NOTE:\n• 이 시스템은 현재 나열된 기기만 지원합니다.\n  만약 사용하시는 기기가 목록에 없다면, 아직 지원되지 않습니다.",
		NoteInfo2:         "💡 사용 중인 기기가 어떤 제품인지 모르는 경우, https://lcdyk0517.github.io/dtbTools.html 을 이용하여 확인하세요.",
		NoteInfo3:         "• 기본 EmuELEC 카드에 포함된 dtb 파일을 이 시스템에 사용하지 마십시오. 부팅이 불가능해집니다.",

		BeforeSelectingConsole: "기기를 선택하기 전에 다음 내용을 읽어주세요:",
		SubInfo:                "  선택한 기기의 필요한 파일이 자동으로 복사됩니다.",
		Continue1:              "  • 계속하려면 Enter 키를 누르고, 종료하려면 'q' 키를 누르세요.",
		Continue2:              "\nEnter 계속，",
		CancelledBye:           "취소되었어요, 안녕! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ 브랜드를 선택하세요",
		SearchOption:      "모델 키워드로 검색",
		SearchPrompt:      "모델 키워드를 입력하세요 (예: r36s, rgb10max, 35h). 빈 입력 = 뒤로: ",
		SearchResultsFmt:  "\"%s\" 검색 결과: ",
		SearchNoResults:   "일치하는 기기를 찾을 수 없어요. 다른 키워드로 시도해 보세요.",
		SearchHint:        "팁: 브랜드를 모르겠나요? 검색을 선택하고 모델명을 입력하세요.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "선택 가능한 기기: ",
		NoConsolesFound:        "기기를 찾을 수 없어요.",
		Copying:                "복사중",
		CopyingExtra:           "기타 리소스 복사중...",
		CopyingFmt:             "  복사중: %s\n",
		SelectBatteryVersion:   "배터리 드라이버 버전을 선택하세요:",
		BatteryVersionOriginal: "1. arkos 오리지널 드라이버 (이 드라이버는 batteryplus와 함께 사용해야 하며, 그렇지 않으면 충전 시 배터리 잔량이 비정상적으로 표시됩니다.)",
		BatteryVersionFix:      "2. arkos4clone 배터리 드라이버 (충전 및 사용 중에 배터리 잔량을 정확하게 표시할 수 있으며, 노화 적응 기능을 갖추고 있습니다.)",
		CloneR36sNote: "참고:\n" +
			"• 'With Amplifier'와 'Without Amplifier'는 오디오 출력만 다릅니다.\n" +
			"  하나에서 소리가 나지 않으면 다른 것을 시도하세요.\n" +
			"• 기본 DTB에서 오른쪽 조이스틱의 상/하 방향이 반전되어 있다면,\n" +
			"  이름에 'Invert Right Joystick'이 포함된 옵션을 사용하여 수정하세요.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  성공!",
		ModelsCopied:         "복제된 모델： ",
		Tip1:                 "  팁: 대상 폴더의 파일을 확인하십시오.",
		CleanTargetDir:       "불필요한 파일 정리...",
		DeleteFileFmt:        "  파일삭제: %s\n",
		DeletionFailedFmt:    "    경고: 삭제실패 %s: %v\n",
		DeleteDirectoryFmt:   "  폴더 삭제: %s\n",
		DirDeletionFailedFmt: "    경고: 폴더 삭제 실패 %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "언어 선택:",
		DefaultEnglish:    "  1. English (기본)",
		Info1:             "번호를 입력하거나 Enter 키를 누르세요. 기본 설정은 영어입니다:",
		TagFileCreated:    "중국어 태그 파일이 생성되었어요. (.ko created)",
		OperationComplete: "작업이 완료되었어요! 언어가 선택되었어요: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "오버클럭 매개변수를 조정하시겠습니까?",
		OverclockTitle:       "오버클럭 매개변수 설정",
		MaxFreqLabel:         "최대 주파수 (부팅 후 ES에서 표시되는 최대 주파수)",
		BootFreqLabel:        "부팅 주파수 (시스템 부팅 시 사용되는 주파수)",
		BootFreqMustLE:       "부팅 주파수는 최대 주파수 이하여야 합니다",
		DefaultFreqNote:      "기본 주파수는 정상 부팅을 보장합니다. 기본을 초과하는 옵션은 빨간색으로 표시됩니다.",
		RedWarning:           "경고: 기본 주파수를 초과하면 시스템이 멈출 수 있습니다!",
		FreezeWarning:        "시스템이 멈추면 주파수를 낮추세요.",
		CurrentConfig:        "현재 설정:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "메모리",
		MaxFreq:              "최대",
		BootFreq:             "부팅",
		ApplyOverclock:       "boot.ini에 오버클럭 매개변수를 적용 중...",
		OverclockApplied:     "오버클럭 매개변수가 성공적으로 적용되었습니다!",
		UsingDefaults:        "기본 오버클럭 매개변수 사용 (1296/520/666).",
		DDRCloneDefault:      "클론 기본",
		DDROriginalDefault:   "오리지널 기본",
		OCWarning: "경고: 이 모드에서 발생하는 버그에 대해 issues를 제출하지 마세요.\n" +
			"  CPU 손상은 사용자 책임입니다.\n" +
			"  이해하지 못하셨다면 N을 선택하세요.\n" +
			"\n" +
			"  참고로 이 시스템은 스피커를 손상시키지 않습니다.\n" +
			"  그런 위험이 걱정된다면 사용하지 마세요.\n" +
			"  이런 터무니없는 소문이 왜 퍼지는지 모르겠습니다.",
		GPUDDRFreezeTip:      "시스템 진입 후 멈춤 현상이 발생하면 주파수를 낮추세요.",
		AskVoltage:           "안정성을 높이기 위해 전압을 올리시겠습니까?",
		VoltageTitle:         "전압 인상 설정",
		VoltageWarning:       "경고: 전압을 올리면 하드웨어가 손상될 수 있습니다!",
		VoltageConfirmPrompt: "위험을 이해했음을 확인하려면 입력하세요: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "확인 텍스트 입력: ",
		VoltageWrongInput:    "입력이 올바르지 않습니다. 전압 인상이 취소되었습니다.",
		VoltageApplied:       "전압 인상이 성공적으로 적용되었습니다!",
		VoltageSkipped:       "전압 인상을 건너뛰었습니다.",
	},
}
