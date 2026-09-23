package console

// ConsoleConfig describes a supported console target.
type ConsoleConfig struct {
	RealName     string
	BrandEntries []BrandEntry
	ExtraSources []string
	Keywords     []string
}

// BrandEntry maps a brand to a human-readable display name.
type BrandEntry struct {
	Brand       string
	DisplayName string
}

// Consoles lists all supported console configurations.
var Consoles = []ConsoleConfig{
	{
		RealName: "a10mini",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "a10miniv4",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI V4"},
		},
		ExtraSources: []string{"logo/540P/"},
	},
	{
		RealName: "r36ultra",
		BrandEntries: []BrandEntry{
			{Brand: "UDT", DisplayName: "UDT R36Ultra"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36ultrax",
		BrandEntries: []BrandEntry{
			{Brand: "UDT", DisplayName: "UDT R36UltraX"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "k36s",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole K36S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36t",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole R36T"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36tmax",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole R36T MAX"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "h7",
		BrandEntries: []BrandEntry{
			{Brand: "GUSGU", DisplayName: "GUSGU H7"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "go2",
		BrandEntries: []BrandEntry{
			{Brand: "Lenovo", DisplayName: "Lenovo GO2"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "xu10",
		BrandEntries: []BrandEntry{
			{Brand: "MagicX", DisplayName: "MagicX XU10"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "g350",
		BrandEntries: []BrandEntry{
			{Brand: "Batlexp", DisplayName: "Batlexp G350"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rs16",
		BrandEntries: []BrandEntry{
			{Brand: "CoolBoy", DisplayName: "CoolBoy RS16"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "k36",
		BrandEntries: []BrandEntry{
			{Brand: "Kinhank", DisplayName: "K36 Origin Panel"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg351mp",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351MP"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg351p",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351P"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rg351v panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351V Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg351v panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351V Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rp1",
		BrandEntries: []BrandEntry{
			{Brand: "RetroBox", DisplayName: "RetroBox P1"},
		},
		ExtraSources: []string{"logo/480P-270/"},
	},
	{
		RealName: "rgb10",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rgbv10",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGBV10"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rgb10x",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10X"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rgb10max1",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10Max1"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "rgb10max2",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10Max2"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "rgb20s",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB20S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel1 amp",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 1 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 1 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel1 invert",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 1 Without Amplifier And Invert Right Joystick"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel3",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 3"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel4",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 4"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel5",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 5"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel5 invert",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 5 Invert Right Joystick"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 panel6",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Panel 6"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type2 panel1 amp",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 Panel 1 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type2 panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 Panel 1 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type2 panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r46h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R46H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r40xxpromax",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX ProMax"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r40xx",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r36hpromax",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36H ProMax"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r45h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R45H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r36splus",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36sPlus"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r33s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R33s"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel0",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 0"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel1",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel2",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel3",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 3"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel4 type1",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4 Type 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel4 type2",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4 Type 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "v21 panel4 rumble test",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s v21 Rumble Fix (Risk unknown. For testing purposes only.)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36xx",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36XX"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "o30s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole O30S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r50s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R50S"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "r50h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R50H"},
		},
		ExtraSources: []string{"logo/720x1280P/"},
	},
	{
		RealName: "sauce panel1",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel2",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel3",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 3"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel4",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 4"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel5",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 5 [TEST]"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "dr28s",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "Diium Dr28s"},
		},
		ExtraSources: []string{"logo/480P-270/"},
	},
	{
		RealName: "d007",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "SZDiiER D007(Plus)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "mymini",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mymini"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "mini40",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mini40"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type1",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 1"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type2",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 2"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type3",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 3[thanks Pandryl]"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36pro",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Pro"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xf35h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF35H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rf35h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF35H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xf40h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40H"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "rf40h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF40H"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "dc35v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC35V"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "dc40v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC40V"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "xf40v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40V"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "xf28",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF28"},
		},
		ExtraSources: []string{"logo/480P-1/"},
	},
	{
		RealName: "r36max2",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max2"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "xf45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "dc45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf45h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF45H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf55h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF55H"},
		},
		ExtraSources: []string{"logo/720x1280P-90/"},
	},
	{
		RealName: "hg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole HG36 (HG3506)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rx6h",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RX6H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xgb36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole XGB36 (G26)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "t16max",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole T16MAX"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "u8 panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8 Panel 1"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
	{
		RealName: "u8 panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8 Panel 2"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
	{
		RealName: "rg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RG36"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg36pro",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RG36Pro"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r40s",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole R40S (RK3326 Without L2/R2)"},
			{Brand: "Other", DisplayName: "GameConsole R39S"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
}

// Brands lists all available brands in order.
var Brands = []string{
	"YMC",
	"UDT",
	"GUSGU",
	"AISLPC",
	"Lenovo",
	"MagicX",
	"Batlexp",
	"CoolBoy",
	"Kinhank",
	"Anbernic",
	"RetroBox",
	"Powkiddy",
	"Clone R36s",
	"GameConsole",
	"SoySauce R36s",
	"Diium(SZDiiER)",
	"XiFan HandHelds",
	"Other",
}
