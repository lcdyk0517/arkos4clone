package ops

import (
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"arkos4clone/dtbtools/internal/i18n"
	"arkos4clone/dtbtools/internal/ui"
)

// CleanTargetDirectory removes old dtb/ini/bmp files from the target directory.
func CleanTargetDirectory(lang *i18n.Language, baseDir string) error {
	cleanup := &lang.Cleanup

	ui.Println("")
	ui.Println(ui.ColorWrap(cleanup.CleanTargetDir, ui.StyleCyan))

	patterns := []string{"*.dtb", "*.ini", "*.orig", "*.tony", ".cn"}
	for _, pat := range patterns {
		matches, err := filepath.Glob(filepath.Join(baseDir, pat))
		if err != nil {
			return err
		}
		for _, f := range matches {
			ui.Printf(cleanup.DeleteFileFmt, f)
			if err := os.Remove(f); err != nil {
				ui.Printf(cleanup.DeletionFailedFmt, f, err)
			}
		}
	}

	bmpPath := filepath.Join(baseDir, "BMPs")
	if _, err := os.Stat(bmpPath); err == nil {
		ui.Printf(cleanup.DeleteDirectoryFmt, bmpPath)
		if err := os.RemoveAll(bmpPath); err != nil {
			ui.Printf(cleanup.DirDeletionFailedFmt, bmpPath, err)
		}
	}
	return nil
}

// CopyFile copies a single file from src to dst.
func CopyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	out, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	defer out.Close()

	buf := make([]byte, 32*1024)
	if _, err := io.CopyBuffer(out, in, buf); err != nil {
		return err
	}
	return nil
}

// CopyDirectory recursively copies a directory tree.
func CopyDirectory(src, dst string) error {
	info, err := os.Stat(src)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("source is not a directory: %s", src)
	}

	return filepath.WalkDir(src, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		targetPath := filepath.Join(dst, rel)
		if d.IsDir() {
			if err := os.MkdirAll(targetPath, 0o755); err != nil {
				return err
			}
			return nil
		}
		return CopyFile(path, targetPath)
	})
}

// OverclockConfig holds selected overclocking values.
type OverclockConfig struct {
	CPU     FreqSelection
	GPU     FreqSelection
	DDR     FreqSelection
	Voltage bool
}

// FreqSelection holds max and boot frequencies.
type FreqSelection struct {
	MaxFreq  int
	BootFreq int
}

// FreqOption represents a selectable frequency.
type FreqOption struct {
	Value int
}

var cpuFreqOptions = []FreqOption{
	{408}, {600}, {816}, {1008}, {1200}, {1248}, {1296},
	{1368}, {1416}, {1440}, {1464}, {1488}, {1512}, {1608},
}

var gpuFreqOptions = []FreqOption{
	{200}, {300}, {400}, {480}, {520}, {600}, {650},
}

var ddrFreqOptions = []FreqOption{
	{194}, {328}, {450}, {528}, {666}, {786}, {924}, {1040},
}

// SelectBatteryVersion asks the user which battery driver to use.
func SelectBatteryVersion(lang *i18n.Language) (string, error) {
	ui.ClearScreen()
	ui.Println("")
	ui.BoxHeader(lang.Menu3.SelectBatteryVersion)
	ui.Println(lang.Menu3.BatteryVersionOriginal)
	ui.Println(lang.Menu3.BatteryVersionFix)

	for {
		choice, err := ui.ReadIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return "", err
		}
		switch choice {
		case 1:
			return "original", nil
		case 2:
			return "arkos4clone_fix", nil
		default:
			ui.Println(ui.ColorWrap(lang.Common.InvalidSelection, ui.StyleRed))
		}
	}
}

// SelectFrequency renders a frequency selection menu.
func SelectFrequency(lang *i18n.Language, label string, options []FreqOption, defaultVal int, defaultLabels map[int]string, extremeFreq int) (int, error) {
	for {
		ui.ClearScreen()
		ui.Println("")
		ui.Println(ui.ColorWrap(label, ui.StyleBoldGreen))
		for i, opt := range options {
			prefix := fmt.Sprintf("  %d. %d MHz", i+1, opt.Value)
			if lbl, ok := defaultLabels[opt.Value]; ok {
				ui.Printf("%s %s\n", prefix, ui.ColorWrap("("+lbl+")", ui.StyleBoldCyan))
			} else if opt.Value == defaultVal {
				ui.Printf("%s %s\n", prefix, ui.ColorWrap("(Default)", ui.StyleBoldCyan))
			} else if extremeFreq > 0 && opt.Value == extremeFreq {
				ui.Println(ui.ColorWrap(prefix, ui.StyleBoldDeepRed))
			} else if opt.Value > defaultVal {
				ui.Println(ui.ColorWrap(prefix, ui.StyleRed))
			} else {
				ui.Println(prefix)
			}
		}
		ui.Println("")
		choice, err := ui.ReadIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return 0, err
		}
		if choice >= 1 && choice <= len(options) {
			return options[choice-1].Value, nil
		}
		ui.Println(ui.ColorWrap(lang.Common.InvalidSelection, ui.StyleRed))
	}
}

// SelectOverclocking runs the overclocking configuration flow.
func SelectOverclocking(lang *i18n.Language) (*OverclockConfig, error) {
	ui.ClearScreen()
	ui.Println("")
	ui.BoxHeader(lang.Overclock.OverclockTitle)
	ui.Println(ui.ColorWrap(lang.Overclock.DefaultFreqNote, ui.StyleCyan))
	ui.Println(ui.ColorWrap(lang.Overclock.FreezeWarning, ui.StyleBoldRed))
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Overclock.AskOverclock, ui.StyleBoldGreen))
	ui.Println("  1. Yes")
	ui.Println("  2. No")

	choice, err := ui.ReadIntChoice(lang, lang.Common.SelectNumber)
	if err != nil {
		return nil, err
	}
	if choice != 1 {
		return nil, nil
	}

	ui.ClearScreen()
	ui.Println("")
	ui.BoxHeader(lang.Overclock.OCWarning)
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Overclock.FreezeWarning, ui.StyleBoldRed))
	ui.Println("")
	ui.WaitEnter(lang.Common.PressEnterToContinue)

	cfg := &OverclockConfig{
		CPU: FreqSelection{MaxFreq: 1296, BootFreq: 1296},
		GPU: FreqSelection{MaxFreq: 520, BootFreq: 520},
		DDR: FreqSelection{MaxFreq: 666, BootFreq: 666},
	}

	ddrLabels := map[int]string{666: lang.Overclock.DDRCloneDefault, 786: lang.Overclock.DDROriginalDefault}

	cpuMax, err := SelectFrequency(lang, lang.Overclock.ConfigCPU+" - "+lang.Overclock.MaxFreqLabel, cpuFreqOptions, 1296, nil, 1608)
	if err != nil {
		return nil, err
	}
	cfg.CPU.MaxFreq = cpuMax

	cpuBoot, err := SelectFrequency(lang, lang.Overclock.ConfigCPU+" - "+lang.Overclock.BootFreqLabel, filterFreqOptions(cpuFreqOptions, cpuMax), 1296, nil, 1608)
	if err != nil {
		return nil, err
	}
	cfg.CPU.BootFreq = cpuBoot

	gpuFreq, err := SelectFrequency(lang, lang.Overclock.ConfigGPU, gpuFreqOptions, 520, nil, 650)
	if err != nil {
		return nil, err
	}
	cfg.GPU.MaxFreq = gpuFreq
	cfg.GPU.BootFreq = gpuFreq

	ui.Println(ui.ColorWrap(lang.Overclock.GPUDDRFreezeTip, ui.StyleBoldRed))

	ddrFreq, err := SelectFrequency(lang, lang.Overclock.ConfigDDR, ddrFreqOptions, 666, ddrLabels, 1040)
	if err != nil {
		return nil, err
	}
	cfg.DDR.MaxFreq = ddrFreq
	cfg.DDR.BootFreq = ddrFreq

	voltage, err := SelectVoltage(lang)
	if err != nil {
		return nil, err
	}
	cfg.Voltage = voltage

	return cfg, nil
}

func filterFreqOptions(options []FreqOption, maxVal int) []FreqOption {
	var filtered []FreqOption
	for _, opt := range options {
		if opt.Value <= maxVal {
			filtered = append(filtered, opt)
		}
	}
	return filtered
}

// SelectVoltage runs the voltage increase confirmation flow.
func SelectVoltage(lang *i18n.Language) (bool, error) {
	ui.ClearScreen()
	ui.Println("")
	ui.BoxHeader(lang.Overclock.VoltageTitle)
	ui.Println(ui.ColorWrap(lang.Overclock.VoltageWarning, ui.StyleBoldRed))
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Overclock.AskVoltage, ui.StyleBoldGreen))
	ui.Println("  1. Yes")
	ui.Println("  2. No")

	choice, err := ui.ReadIntChoice(lang, lang.Common.SelectNumber)
	if err != nil {
		return false, err
	}
	if choice != 1 {
		ui.Println(ui.ColorWrap(lang.Overclock.VoltageSkipped, ui.StyleCyan))
		return false, nil
	}

	ui.ClearScreen()
	ui.Println("")
	ui.BoxHeader(lang.Overclock.VoltageWarning)
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Overclock.VoltageConfirmPrompt, ui.StyleBoldGreen))
	ui.Println(ui.ColorWrap(lang.Overclock.VoltageConfirmText, ui.StyleBoldCyan))
	ui.Println("")

	resp, err := ui.Prompt(lang.Overclock.VoltageInputPrompt)
	if err != nil {
		return false, err
	}

	if strings.TrimSpace(strings.ToLower(resp)) != strings.ToLower(lang.Overclock.VoltageConfirmText) {
		ui.Println(ui.ColorWrap(lang.Overclock.VoltageWrongInput, ui.StyleRed))
		return false, nil
	}

	ui.Println(ui.ColorWrap(lang.Overclock.VoltageApplied, ui.StyleBoldGreen))
	return true, nil
}

// ApplyOverclockingToBootIni writes overclocking parameters into boot.ini.
func ApplyOverclockingToBootIni(baseDir string, oc *OverclockConfig) error {
	bootIni := filepath.Join(baseDir, "boot.ini")
	data, err := os.ReadFile(bootIni)
	if err != nil {
		return err
	}

	content := string(data)

	ocArgs := fmt.Sprintf("max_cpufreq=%d boot_cpufreq=%d max_gpufreq=%d max_ddrfreq=%d",
		oc.CPU.MaxFreq, oc.CPU.BootFreq, oc.GPU.MaxFreq, oc.DDR.MaxFreq)
	re := regexp.MustCompile(`(setenv\s+bootargs\s+"[^"]*?)((?:\s+(?:max_cpufreq|boot_cpufreq|max_gpufreq|boot_gpufreq|max_ddrfreq|boot_ddrfreq)=\d+)*)\s*"`)
	if re.MatchString(content) {
		content = re.ReplaceAllString(content, "${1} "+ocArgs+"\"")
	}

	if oc.Voltage {
		content = strings.Replace(content,
			`setenv dtb_loadaddr "0x01f00000"`,
			"setenv dtb_loadaddr \"0x01f00000\"\nsetenv dtbo_loadaddr \"0x01f30000\"", 1)

		lines := strings.Split(content, "\n")
		var newLines []string
		for _, line := range lines {
			newLines = append(newLines, line)
			if strings.Contains(line, "load mmc 1:1 ${dtb_loadaddr}") {
				newLines = append(newLines, "load mmc 1:1 ${dtbo_loadaddr} consoles/dtbo/rk3326-oc-voltage.dtbo")
				newLines = append(newLines, "")
				newLines = append(newLines, "fdt addr ${dtb_loadaddr}")
				newLines = append(newLines, "fdt resize 8192")
				newLines = append(newLines, "fdt apply ${dtbo_loadaddr}")
			}
		}
		content = strings.Join(newLines, "\n")
	}

	return os.WriteFile(bootIni, []byte(content), 0644)
}

// CopySelectedConsole performs the full copy flow for a selected console.
func CopySelectedConsole(lang *i18n.Language, selected *ui.ConsoleOption, baseDir string) error {
	if selected == nil || selected.Config == nil {
		return fmt.Errorf("no console selected")
	}

	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Menu3.Copying+selected.DisplayName, ui.StyleCyan))

	srcPath := filepath.Join(baseDir, "consoles", selected.Config.RealName)
	if _, err := os.Stat(srcPath); os.IsNotExist(err) {
		return fmt.Errorf("source directory not found: %s", srcPath)
	}

	if err := CopyDirectory(srcPath, baseDir); err != nil {
		return fmt.Errorf("failed to copy console: %v", err)
	}

	batteryVersion, err := SelectBatteryVersion(lang)
	if err != nil {
		return fmt.Errorf("failed to select battery version: %v", err)
	}
	if batteryVersion != "" {
		kernelSrc := filepath.Join(baseDir, "consoles", "kernel", batteryVersion, "Image")
		if _, err := os.Stat(kernelSrc); err == nil {
			ui.Printf(lang.Menu3.CopyingFmt, "kernel/"+batteryVersion+"/Image")
			if err := CopyFile(kernelSrc, filepath.Join(baseDir, "Image")); err != nil {
				return fmt.Errorf("failed to copy kernel Image: %v", err)
			}
		} else {
			ui.Printf("  Warning: Kernel Image not found: %s\n", kernelSrc)
		}
	}

	ocCfg, err := SelectOverclocking(lang)
	if err != nil {
		return fmt.Errorf("failed to select overclocking: %v", err)
	}
	if ocCfg != nil {
		ui.Println(ui.ColorWrap(lang.Overclock.ApplyOverclock, ui.StyleCyan))
		if err := ApplyOverclockingToBootIni(baseDir, ocCfg); err != nil {
			return fmt.Errorf("failed to apply overclocking: %v", err)
		}
		ui.Println(ui.ColorWrap(lang.Overclock.OverclockApplied, ui.StyleBoldGreen))
	} else {
		ui.Println(ui.ColorWrap(lang.Overclock.UsingDefaults, ui.StyleCyan))
	}

	ui.Println(ui.ColorWrap(lang.Menu3.CopyingExtra, ui.StyleCyan))
	for _, extra := range selected.Config.ExtraSources {
		extraSrc := filepath.Join(baseDir, "consoles", extra)
		if _, err := os.Stat(extraSrc); err == nil {
			ui.Printf(lang.Menu3.CopyingFmt, extra)
			if err := CopyDirectory(extraSrc, baseDir); err != nil {
				return fmt.Errorf("failed to copy extra source %s: %v", extra, err)
			}
		} else {
			ui.Printf("  Warning: Extra source not found: %s\n", extra)
		}
	}

	return nil
}

// ShowSuccessFancy prints the success message.
func ShowSuccessFancy(lang *i18n.Language, consoleName string) {
	ui.Println("")
	ui.Println(ui.ColorWrap(strings.Repeat("=", 64), ui.StyleCyan))
	ui.Println(ui.ColorWrap(lang.Cleanup.OperationCompleted, ui.StyleBoldGreen))
	ui.Printf("  %s\n", ui.ColorWrap(lang.Cleanup.ModelsCopied+consoleName, ui.StyleBoldBlue))
	ui.Println(ui.ColorWrap(lang.Cleanup.Tip1, ui.StyleCyan))
	ui.Println(ui.ColorWrap(strings.Repeat("=", 64), ui.StyleCyan))

	ui.WaitEnter(lang.Common.PressEnterToContinue)
}
