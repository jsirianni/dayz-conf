#!/usr/bin/env bash

set -e

# Pass steam username as argument
if [ -z "$1" ]; then
    echo "Usage: $0 <steam_username>"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    # check if user has sudo privileges
    sudo -v
    if [ $? -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi
fi

STEAM_USER="$1"
DAYZ_APP_ID=223350
DAYZ_WORKSHOP_ID=221100

shell_home="/opt/dayz"

mod_cf="1559212036"
mod_vpp="1828439124"
mod_deerisle="1602372402"
mod_party="1582671564"
mod_buildanywhere="1854626456"
mod_bbp="1710977250"
mod_snafu_weapons="2443122116"
mod_mmg="2663169692"

dayz() {
    sudo -u dayz 'bash' <<EOF
/usr/games/steamcmd \
    +force_install_dir "$shell_home" \
    +login "$STEAM_USER" \
    +app_update "$DAYZ_APP_ID" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_cf" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_vpp" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_deerisle" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_party" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_buildanywhere" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_bbp" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_snafu_weapons" \
    +workshop_download_item "$DAYZ_WORKSHOP_ID" "$mod_mmg" \
    +quit
EOF
}

# symlinks links the mod and key directories. NOTE: Sometimes the key directory
# is capitalized.
symlinks() {
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_cf" "/opt/dayz/$mod_cf"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_vpp" "/opt/dayz/$mod_vpp"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_deerisle" "/opt/dayz/$mod_deerisle"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_party" "/opt/dayz/$mod_party"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_buildanywhere" "/opt/dayz/$mod_buildanywhere"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_bbp" "/opt/dayz/$mod_bbp"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_snafu_weapons" "/opt/dayz/$mod_snafu_weapons"
    sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_mmg" "/opt/dayz/$mod_mmg"

    # CF and Online Tools share the same keyadmins.cfg

    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_cf/keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_vpp/keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_deerisle/Keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_party/Keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_buildanywhere/Keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_bbp/keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_snafu_weapons/Keys/*" /opt/dayz/keys/
    eval sudo ln -sf "/opt/dayz/steamapps/workshop/content/221100/$mod_mmg/keys/*" /opt/dayz/keys/

    sudo chown -R dayz:dayz /opt/dayz
}

systemd() {
    sudo tee /etc/systemd/system/dayz.service > /dev/null <<EOF
[Unit]
Description=DayZ Dedicated Server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target

[Service]
#ExecStartPre=/opt/update.sh
ExecStart=/opt/dayz/DayZServer \
    -config=serverDZ.cfg \
    -port=2601 \
    -mod="$mod_cf;$mod_vpp;$mod_deerisle;$mod_party;$mod_buildanywhere;$mod_bbp;$mod_snafu_weapons;$mod_mmg;" \
    -BEpath=battleye \
    -profiles=profiles \
    -dologs \
    -adminlog \
    -netlog \
    -freezecheck
WorkingDirectory=/opt/dayz
LimitNOFILE=100000
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s INT \$MAINPID
User=dayz
Group=dayz
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
}

dayz
symlinks
systemd
