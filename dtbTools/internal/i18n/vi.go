package i18n

var Vietnamese = Language{
	Title:   "Công cụ Chọn DTB - Phiên bản Go",
	Variant: "vi",
	Common: CommonStrings{
		Exit:                 " Thoát : ",
		SelectNumber:         "\nChọn số: ",
		InvalidSelection:     "Lựa chọn không hợp lệ.",
		PleaseEnterNumber:    "Vui lòng nhập một số",
		PressEnterToContinue: "Nhấn Enter để tiếp tục...",
		Back:                 "Quay lại",
		GoodBye:              "Tạm biệt!",
	},
	Menu1: Menu1Strings{
		SelectYourConsole: "Trình chọn DTB - Chọn Console của bạn",
		Welcome:           "\n================ Chào mừng ================",
		NoteInfo1:         "LƯU Ý:\n• Hệ thống này hiện chỉ hỗ trợ các bản sao R36 được liệt kê;\n  nếu bản sao của bạn không có trong danh sách, nó chưa được hỗ trợ.",
		NoteInfo2:         "💡 Nếu bạn không biết bản sao nào là thiết bị của mình, hãy sử dụng https://lcdyk0517.github.io/dtbTools.html để giúp xác định nó",
		NoteInfo3:         "• KHÔNG sử dụng các tệp dtb từ thẻ EmuELEC gốc với hệ thống này - nó sẽ chặn quá trình khởi động.",

		BeforeSelectingConsole: "Trước khi chọn console:",
		SubInfo:                "  sau đó sao chép console đã chọn và bất kỳ nguồn bổ sung nào được ánh xạ.",
		Continue1:              "  • Nhấn Enter để tiếp tục; nhập 'q' để thoát.",
		Continue2:              "\nNhấn Enter để tiếp tục, Nhấn ",
		CancelledBye:           "Đã hủy, tạm biệt! 👋",
	},
	Menu2: Menu2Strings{
		PleaseSelectBrand: "│ Vui lòng chọn một thương hiệu",
		SearchOption:      "Tìm kiếm theo từ khóa mô hình",
		SearchPrompt:      "Nhập từ khóa mô hình (ví dụ: r36s, rgb10max, 35h). Trống = quay lại: ",
		SearchResultsFmt:  "Kết quả tìm kiếm cho: \"%s\"",
		SearchNoResults:   "Không tìm thấy console phù hợp. Thử từ khóa khác.",
		SearchHint:        "Mẹo: Không biết thương hiệu của thiết bị bạn là gì? Chọn Tìm kiếm và chỉ cần nhập tên mô hình.",
	},
	Menu3: Menu3Strings{
		AvailableConsolesFor:   "Console có sẵn cho: ",
		NoConsolesFound:        "Không tìm thấy console.",
		Copying:                "Đang sao chép: ",
		CopyingExtra:           "Đang sao chép tài nguyên bổ sung...",
		CopyingFmt:             "  Đang sao chép: %s\n",
		SelectBatteryVersion:   "Chọn phiên bản trình điều khiển pin:",
		BatteryVersionOriginal: "1. trình điều khiển gốc arkos (trình điều khiển này phải được sử dụng cùng với batteryplus; nếu không, mức pin sẽ hiển thị bất thường trong quá trình sạc).",
		BatteryVersionFix:      "2. trình điều khiển pin arkos4clone (có thể hiển thị chính xác mức pin trong cả quá trình sạc và xả, và có chức năng thích ứng với lão hóa)",
		CloneR36sNote: "LƯU Ý:\n" +
			"• 'Có Bộ Khuếch Đại' và 'Không Có Bộ Khuếch Đại' chỉ khác nhau về đầu ra âm thanh.\n" +
			"  Nếu một trong số đó không có âm thanh, hãy thử cái kia.\n" +
			"• Nếu hướng lên/xuống của joystick bên phải bị đảo ngược trong DTB mặc định,\n" +
			"  hãy sử dụng tùy chọn có 'Invert Right Joystick' trong tên để sửa nó.",
	},
	Cleanup: CleanupStrings{
		OperationCompleted:   "  ✅  Hoạt động đã hoàn thành!",
		ModelsCopied:         "Các mô hình đã được sao chép： ",
		Tip1:                 "  Mẹo: Kiểm tra các tệp trong thư mục đích.",
		CleanTargetDir:       "Đang làm sạch thư mục đích...",
		DeleteFileFmt:        "  Xóa tệp: %s\n",
		DeletionFailedFmt:    "    Cảnh báo: Xóa không thành công %s: %v\n",
		DeleteDirectoryFmt:   "  Xóa thư mục: %s\n",
		DirDeletionFailedFmt: "    Cảnh báo: Xóa thư mục không thành công %s: %v\n",
	},
	Menu4: Menu4Strings{
		SelectLanguage:    "Chọn ngôn ngữ:",
		DefaultEnglish:    "  1. English (Mặc định)",
		Info1:             "Nhập số hoặc nhấn Enter. English là lựa chọn mặc định: ",
		TagFileCreated:    "Tệp thẻ ngôn ngữ tiếng Trung đã được tạo. (.cn đã tạo)",
		OperationComplete: "Hoạt động hoàn tất! Ngôn ngữ đã chọn: ",
	},
	Overclock: OverclockStrings{
		AskOverclock:         "Bạn có muốn điều chỉnh tham số ép xung không?",
		OverclockTitle:       "Cấu hình Tham số Ép xung",
		MaxFreqLabel:         "Tần số tối đa (có thể nhìn thấy trong ES sau khi khởi động)",
		BootFreqLabel:        "Tần số khởi động (được sử dụng trong quá trình khởi động hệ thống)",
		BootFreqMustLE:       "Tần số khởi động phải <= tần số tối đa",
		DefaultFreqNote:      "Các tần số mặc định đảm bảo khởi động bình thường. Các tần số vượt quá mặc định được hiển thị bằng màu ĐỎ.",
		RedWarning:           "CẢNH BÁO: Vượt quá tần số mặc định có thể gây treo hệ thống!",
		FreezeWarning:        "Nếu hệ thống bị treo, vui lòng giảm tần số.",
		CurrentConfig:        "Cấu hình hiện tại:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Tối đa",
		BootFreq:             "Khởi động",
		ApplyOverclock:       "Đang áp dụng tham số ép xung vào boot.ini...",
		OverclockApplied:     "Tham số ép xung đã được áp dụng thành công!",
		UsingDefaults:        "Sử dụng tham số ép xung mặc định (1296/520/666).",
		DDRCloneDefault:      "Mặc định bản sao",
		DDROriginalDefault:   "Mặc định gốc",
		OCWarning: "CẢNH BÁO: Ở chế độ này, KHÔNG gửi issues cho bất kỳ lỗi nào.\n" +
			"  Mọi hư hỏng CPU là trách nhiệm của bạn.\n" +
			"  Nếu bạn không hiểu điều này, vui lòng chọn N.\n" +
			"\n" +
			"  Ồ, nhân tiện, hệ thống này KHÔNG làm hỏng loa của bạn.\n" +
			"  Nếu bạn lo lắng về rủi ro đó, đừng sử dụng nó.\n" +
			"  Chúng tôi không có ý tưởng nào về tại sao những lời đồn đại nực cười như vậy lại lan truyền.",
		GPUDDRFreezeTip:      "Nếu hệ thống bị treo sau khi vào, hãy giảm tần số.",
		AskVoltage:           "Bạn có muốn tăng điện áp để ổn định hơn không?",
		VoltageTitle:         "Cấu hình Tăng Điện Áp",
		VoltageWarning:       "CẢNH BÁO: Tăng điện áp có thể gây hư hỏng phần cứng!",
		VoltageConfirmPrompt: "Để xác nhận bạn hiểu rõ rủi ro, hãy nhập: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Nhập xác nhận: ",
		VoltageWrongInput:    "Đầu vào không chính xác. Tăng điện áp đã bị hủy.",
		VoltageApplied:       "Tăng điện áp đã được áp dụng thành công!",
		VoltageSkipped:       "Tăng điện áp đã bị bỏ qua.",
	},
}
