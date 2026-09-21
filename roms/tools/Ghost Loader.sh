#!/bin/bash

#-----------------------------#
#         GhostLoader         #
#          by Jason           #
#-----------------------------#

# --- Vérification Root ---
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

# --- Variables Globales ---
CURR_TTY="/dev/tty1"
WATCHER_SCRIPT="/usr/local/bin/ghostloader_watcher.sh"
SERVICE_FILE="/etc/systemd/system/ghostloader.service"
PROFILES_DIR="/home/ark/.emulationstation/theme_profiles"
ES_SETTINGS="/home/ark/.emulationstation/es_settings.cfg"
STATE_FILE="/tmp/ghostloader_last_theme"
LOG_FILE="/tmp/ghostloader.log"
BACKTITLE_TEXT="GhostLoader - Theme Settings Guardian by Jason"

# --- Sortie Propre ---
ExitMenu() {
    printf "\033c\e[?25h" >"$CURR_TTY"
    pkill -f "gptokeyb -1 GhostLoader.sh" >"$CURR_TTY"|| true
    exit 0
}

# --- Création du script de surveillance ---
create_watcher_script() {
    rm -f "$WATCHER_SCRIPT"
    cat > "$WATCHER_SCRIPT" << 'EOF'
#!/bin/bash
# GhostLoader Watcher by Jason

ES_SETTINGS="/home/ark/.emulationstation/es_settings.cfg"
PROFILES_DIR="/home/ark/.emulationstation/theme_profiles"
LOG_FILE="/tmp/ghostloader.log"
# Fichier de sauvegarde pour conserver l'état précédent complet
PREVIOUS_SETTINGS_BAK="/tmp/es_settings.ghostloader.bak"

log() {
    echo "$(/bin/date --rfc-3339=seconds) :: $1" >> "$LOG_FILE"
}

get_theme_name() {
    local theme
    theme=$(/bin/grep 'ThemeSet' "$1" 2>/dev/null | /bin/sed 's/.*value="\([^"]*\)".*/\1/')
    if [ -z "$theme" ]; then
        theme="default"
    fi
    echo "$theme"
}

save_profile() {
    local theme_name="$1"
    local source_file="$2"
    if [ -z "$theme_name" ] || [ ! -f "$source_file" ]; then return; fi
    
    log "Saving full settings profile for '$theme_name' from source '$source_file'..."
    /bin/mkdir -p "$PROFILES_DIR"
    /bin/cp "$source_file" "$PROFILES_DIR/$theme_name.profile" || log "WARNING: Failed to save profile."
}

restore_profile() {
    local theme_name="$1"
    local profile_path="$PROFILES_DIR/$theme_name.profile"

    if [ -f "$profile_path" ]; then
        log "Restoring full settings profile for '$theme_name'..."
        /bin/cp "$profile_path" "$ES_SETTINGS.tmp" && /bin/mv "$ES_SETTINGS.tmp" "$ES_SETTINGS"
    else
        log "No profile found for '$theme_name'. ES will use its defaults."
        # S'il n'y a pas de profil, on s'assure quand même que le nom du thème est correct dans le fichier actuel
        /bin/sed -i "s|<string name=\"ThemeSet\" value=\".*\" />|<string name=\"ThemeSet\" value=\"${theme_name}\" />|" "$ES_SETTINGS"
    fi
}

log "GhostLoader service starting."

# Si notre sauvegarde n'existe pas, on la crée à partir du fichier actuel
if [ ! -f "$PREVIOUS_SETTINGS_BAK" ] && [ -f "$ES_SETTINGS" ]; then
    log "Initializing settings backup."
    /bin/cp "$ES_SETTINGS" "$PREVIOUS_SETTINGS_BAK"
fi

while true; do
    sleep 0.5
    if [ ! -f "$ES_SETTINGS" ]; then continue; fi

    # On compare les fichiers. Si rien n'a changé, on ne fait rien.
    if /usr/bin/cmp -s "$ES_SETTINGS" "$PREVIOUS_SETTINGS_BAK"; then
        continue
    fi

    CURRENT_THEME=$(get_theme_name "$ES_SETTINGS")
    LAST_THEME=$(get_theme_name "$PREVIOUS_SETTINGS_BAK")

    if [ "$CURRENT_THEME" != "$LAST_THEME" ]; then
        log "THEME CHANGE DETECTED! From '$LAST_THEME' to '$CURRENT_THEME'."
    sleep 1
        
        # On sauvegarde le profil de l'ancien thème en utilisant notre sauvegarde.
        save_profile "$LAST_THEME" "$PREVIOUS_SETTINGS_BAK"
        
         # Arrêt complet d’EmulationStation
        log "Stopping EmulationStation completely..."
        pkill -9 -f "/usr/bin/emulationstation/emulationstation" || true
        pkill -9 -f "/usr/bin/emulationstation/emulationstation.sh" || true

        # Attente complète de l’arrêt
        for i in {1..10}; do
            if ! pgrep -f "/usr/bin/emulationstation/emulationstation" >/dev/null; then
                break
            fi
            log "Waiting for EmulationStation to fully stop..."
            sleep 1
        done

        # Restaure le profil du nouveau thème
        log "Restoring profile for '$CURRENT_THEME'..."
        restore_profile "$CURRENT_THEME"
        /bin/cp "$ES_SETTINGS" "$PREVIOUS_SETTINGS_BAK"
        sleep 1

        # On lock notre fichier temporairement
        log "LOCKING es_settings.cfg..."
        /usr/bin/chattr +i "$ES_SETTINGS"

        # Relance EmulationStation
        log "Starting EmulationStation safely on TTY1..."
        sudo -u ark /usr/bin/openvt -s -w -- /bin/bash -c \
            "XDG_RUNTIME_DIR=/run/user/1000 /usr/bin/emulationstation/emulationstation.sh" \
            >/dev/null 2>&1 &

        # Attente pour que ES démarre proprement
        log "Waiting 12 seconds for ES to reload..."
        sleep 12

        # Rétablit l’accès au fichier
        log "UNLOCKING es_settings.cfg..."
        /usr/bin/chattr -i "$ES_SETTINGS"

        log "--- CYCLE COMPLETE ---"
        sleep 5

    fi
    
    # On met à jour notre fichier de sauvegarde avec la version la plus récente
    # Mise à jour différée pour éviter d’écraser le backup trop tôt
sleep 0.5
log "Updating settings backup to the latest version."
/bin/cp "$ES_SETTINGS" "$PREVIOUS_SETTINGS_BAK"

done
EOF
    chmod 755 "$WATCHER_SCRIPT"
    chown ark:ark "$WATCHER_SCRIPT"
}

# --- GESTION DU SERVICE ---
create_systemd_file() {
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=GhostLoader - Automatic Theme Settings Saver
After=emulationstation.service

[Service]
Type=simple
ExecStartPre=/bin/sleep 5
ExecStart=$WATCHER_SCRIPT
Restart=always
RestartSec=3
User=ark
Environment=XDG_RUNTIME_DIR=/run/user/1000

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$SERVICE_FILE"
    systemctl daemon-reload
}


activate_service() {
    dialog --backtitle "$BACKTITLE_TEXT" --title "Activation" --infobox "\nCreating and activating the GhostLoader service..." 5 57 >"$CURR_TTY"
    >"$LOG_FILE"
    create_watcher_script
    create_systemd_file
    systemctl enable --now ghostloader.service
    sleep 2
    if systemctl is-active --quiet ghostloader.service; then
        dialog --backtitle "$BACKTITLE_TEXT" --title "Activation Successful" --msgbox "\nGhostLoader is now active." 7 32 >"$CURR_TTY"
        ExitMenu
    else
        dialog --backtitle "$BACKTITLE_TEXT" --title "Failure" --msgbox "\nThe service could not be activated." 8 70 >"$CURR_TTY"
    fi
}

deactivate_service() {
    dialog --backtitle "$BACKTITLE_TEXT" --title "Deactivation" --infobox "\nStopping and deactivating the service..." 5 45 >"$CURR_TTY"
    systemctl disable --now ghostloader.service || true
    sleep 2
    dialog --backtitle "$BACKTITLE_TEXT" --title "Deactivation Successful" --msgbox "\nGhostLoader is now deactivated." 7 35 >"$CURR_TTY"
    ExitMenu
}

uninstall_engine() {
    if dialog --backtitle "$BACKTITLE_TEXT" --title "Confirmation" --output-fd 1 --yesno "\nAre you sure you want to uninstall GhostLoader?\n\nAll saved theme profiles will be deleted." 9 57 2>"$CURR_TTY"; then
        systemctl disable --now ghostloader.service || true
        dialog --backtitle "$BACKTITLE_TEXT" --title "Uninstall" --msgbox "\nCleaning up files finished." 7 35 >"$CURR_TTY"
        rm -f "$WATCHER_SCRIPT" "$SERVICE_FILE" "$LOG_FILE" "$STATE_FILE"
        rm -rf "$PROFILES_DIR"
        rm -f /tmp/es_settings.ghostloader.bak
        systemctl daemon-reload
        ExitMenu
    fi
}

# --- Fonction pour voir le contenu d'un profil ---
view_profile_settings() {
    local theme_name="$1"
    local profile_path="$PROFILES_DIR/$theme_name.profile"
    if [ -f "$profile_path" ]; then
        dialog --backtitle "$BACKTITLE_TEXT" --title "Saved Settings for '$theme_name'" --textbox "$profile_path" 22 70 >"$CURR_TTY"
    else
        dialog --backtitle "$BACKTITLE_TEXT" --title "Error" --msgbox "\nProfile file for '$theme_name' not found." 7 40 >"$CURR_TTY"
    fi
}

# --- Menu pour gérer les profils ---
manage_profiles() {
    while true; do
        local profiles=()
        while IFS= read -r profile_file; do
            local theme_name
            theme_name=$(basename "$profile_file" .profile)
            profiles+=("$theme_name" "")
        done < <(find "$PROFILES_DIR" -name "*.profile" 2>/dev/null | sort)

        if [ ${#profiles[@]} -eq 0 ]; then
            dialog --backtitle "$BACKTITLE_TEXT" --title "Manage Profiles" --msgbox "\nNo saved profiles found." 7 35 >"$CURR_TTY"
            return
        fi

        local choice
        choice=$(dialog --backtitle "$BACKTITLE_TEXT" --title "Manage Saved Profiles" --output-fd 1 \
            --cancel-label "Back" \
            --menu "\nSelect a theme profile to manage:" 20 50 10 "${profiles[@]}" 2>"$CURR_TTY")
        
        if [ -z "$choice" ]; then
            break
        fi

        local action
        action=$(dialog --backtitle "$BACKTITLE_TEXT" --title "Actions for '$choice'" --output-fd 1 \
            --cancel-label "Back" \
            --menu "\nWhat do you want to do?" 11 40 3 \
            1 "View Saved Settings" \
            2 "Delete This Profile" \
        2>"$CURR_TTY")

        case "$action" in
            1)
                view_profile_settings "$choice"
                ;;
            2)
                if dialog --backtitle "$BACKTITLE_TEXT" --title "Confirm Deletion" --yesno "\nAre you sure you want to delete the profile for '$choice'?" 8 50 >"$CURR_TTY"; then
                    rm -f "$PROFILES_DIR/$choice.profile"
                    dialog --backtitle "$BACKTITLE_TEXT" --title "Success" --msgbox "\nProfile for '$choice' has been deleted." 8 50 >"$CURR_TTY"
                fi
                ;;
        esac
    done
}

# --- Menu Principal ---
MainMenu() {
    while true; do
        local STATUS="Deactivated"
        if systemctl is-active --quiet ghostloader.service; then
            STATUS="Active"
        fi

        local PROFILE_COUNT
        PROFILE_COUNT=$(find "$PROFILES_DIR" -name "*.profile" 2>/dev/null | wc -l)
        
        local CHOICE
        CHOICE=$(dialog --backtitle "$BACKTITLE_TEXT" --title "GhostLoader Manager" --output-fd 1 \
            --menu "\nThis service automatically saves your theme settings.\n\nService Status: $STATUS\nSaved Profiles: $PROFILE_COUNT\n" 18 58 6 \
            1 "Activate GhostLoader Service" \
            2 "Deactivate GhostLoader Service" \
            3 "Manage Saved Profiles" \
            4 "Uninstall GhostLoader Completely" \
            5 "Exit" \
        2>"$CURR_TTY")
        
        case "$CHOICE" in
            1) activate_service ;;
            2) deactivate_service ;;
            3) manage_profiles ;;
            4) uninstall_engine ;;
            5) ExitMenu ;;
            *) ExitMenu ;;
        esac
    done
}

# --- Point d'entrée du script ---
trap ExitMenu EXIT SIGINT SIGTERM

printf "\033c\e[?25l" >"$CURR_TTY"
dialog --clear
export TERM=linux
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz || true
pkill -9 -f gptokeyb || true
printf "\033c" >"$CURR_TTY"
printf "Starting GhostLoader.\nPlease wait ..." >"$CURR_TTY"
sleep 2

if [ ! -f "$ES_SETTINGS" ]; then
    dialog --backtitle "$BACKTITLE_TEXT" --title "Critical Error" --msgbox "\nThe es_settings.cfg file could not be found." 8 70 >"$CURR_TTY"
    ExitMenu
fi

if command -v /opt/inttools/gptokeyb &> /dev/null; then
    if [[ -e /dev/uinput ]]; then
        chmod 666 /dev/uinput 2>/dev/null || true
    fi
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    /opt/inttools/gptokeyb -1 "GhostLoader.sh" -c "/opt/inttools/keys.gptk" >/dev/null 2>&1 &
fi

printf "\033c" >"$CURR_TTY"

# --- Départ du script ---
MainMenu