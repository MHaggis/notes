#! /bin/bash
# Adopted from the great DetectionLab
# This will install Splunk + BOTSv2 Attack only dataset

install_prerequisites() {
  echo "[$(date +%H:%M:%S)]: Downloading DetectionLab..."
  # Clone DetectionLab for Splunk Apps
  git clone https://github.com/clong/DetectionLab.git /opt/DetectionLab
}

install_splunk() {
  # Check if Splunk is already installed
  if [ -f "/opt/splunk/bin/splunk" ]; then
    echo "[$(date +%H:%M:%S)]: Splunk is already installed"
  else
    echo "[$(date +%H:%M:%S)]: Installing Splunk..."
    # Get download.splunk.com into the DNS cache. Sometimes resolution randomly fails during wget below
    dig @8.8.8.8 download.splunk.com >/dev/null
    dig @8.8.8.8 splunk.com >/dev/null
    dig @8.8.8.8 www.splunk.com >/dev/null

    # Try to resolve the latest version of Splunk by parsing the HTML on the downloads page
    echo "[$(date +%H:%M:%S)]: Attempting to autoresolve the latest version of Splunk..."
    LATEST_SPLUNK=$(curl https://www.splunk.com/en_us/download/splunk-enterprise.html | grep -i deb | grep -Eo "data-link=\"................................................................................................................................" | cut -d '"' -f 2)
    # Sanity check what was returned from the auto-parse attempt
    if [[ "$(echo $LATEST_SPLUNK | grep -c "^https:")" -eq 1 ]] && [[ "$(echo $LATEST_SPLUNK | grep -c "\.deb$")" -eq 1 ]]; then
      echo "[$(date +%H:%M:%S)]: The URL to the latest Splunk version was automatically resolved as: $LATEST_SPLUNK"
      echo "[$(date +%H:%M:%S)]: Attempting to download..."
      wget --progress=bar:force -P /opt "$LATEST_SPLUNK"
    else
      echo "[$(date +%H:%M:%S)]: Unable to auto-resolve the latest Splunk version. Falling back to hardcoded URL..."
      # Download Hardcoded Splunk
      wget --progress=bar:force -O /opt/splunk-8.0.2-a7f645ddaf91-linux-2.6-amd64.deb 'https://download.splunk.com/products/splunk/releases/8.0.2/linux/splunk-8.0.2-a7f645ddaf91-linux-2.6-amd64.deb&wget=true'
    fi
    dpkg -i /opt/splunk*.deb
    /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme
    /opt/splunk/bin/splunk add index wineventlog -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index osquery -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index osquery-status -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index sysmon -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index powershell -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index zeek -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index suricata -auth 'admin:changeme'
    /opt/splunk/bin/splunk add index threathunting -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_forwarder/splunk-add-on-for-microsoft-windows_500.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/add-on-for-microsoft-sysmon_800.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/asn-lookup-generator_101.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/lookup-file-editor_331.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-zeek-aka-bro_400.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/force-directed-app-for-splunk_200.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/punchcard-custom-visualization_130.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/sankey-diagram-custom-visualization_130.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/link-analysis-app-for-splunk_161.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/threathunting_141.tgz -auth 'admin:changeme'

    # Uncomment the following block to install BOTSv2
    # Thanks to @MHaggis for this addition!
    # It is recommended to only uncomment the attack-only dataset comment block.
    # You may also link to the full dataset which is ~12GB if you prefer.
    # More information on BOTSv2 can be found at https://github.com/splunk/botsv2

    ### BOTSv2 COMMENT BLOCK BEGINS ###
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/base64_11.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/jellyfisher_010.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/palo-alto-networks-add-on-for-splunk_611.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/SA-ctf_scoreboard_admin-master.zip  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/SA-ctf_scoreboard-master.zip  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/sa-investigator-for-enterprise-security_200.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-apache-web-server_100.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-microsoft-cloud-services_310.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-microsoft-iis_101.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-microsoft-windows_600.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-symantec-endpoint-protection_230.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-add-on-for-unix-and-linux_602.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-app-for-osquery_10.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-common-information-model-cim_4130.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-security-essentials_241.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-stream_720.tgz -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/splunk-ta-for-suricata_233.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/ssl-certificate-checker_32.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/url-toolbox_16.tgz  -auth 'admin:changeme'
     /opt/splunk/bin/splunk install app /opt/DetectionLab/Vagrant/resources/splunk_server/website-monitoring_274.tgz  -auth 'admin:changeme'

    ### UNCOMMENT THIS BLOCK FOR THE ATTACK-ONLY DATASET (Recommended) ###
     echo "[$(date +%H:%M:%S)]: Downloading Splunk BOTSv2 Attack Only Dataset..."
     wget --progress=bar:force -P /opt/ https://s3.amazonaws.com/botsdataset/botsv2/botsv2_data_set_attack_only.tgz
     echo "[$(date +%H:%M:%S)]: Download Complete."
     echo "[$(date +%H:%M:%S)]: Extracting to Splunk Apps directory"
     tar zxvf /opt/botsv2_data_set_attack_only.tgz -C /opt/splunk/etc/apps/
    ### ATTACK-ONLY COMMENT BLOCK ENDS ###

    ### UNCOMMENT THIS BLOCK FOR THE FULL 12GB DATASET (Not recommended) ###
    # echo "[$(date +%H:%M:%S)]: Downloading Splunk BOTSv2..."
    # wget --progress=bar:force https://s3.amazonaws.com/botsdataset/botsv2/botsv2_data_set.tgz /opt/
    # echo "[$(date +%H:%M:%S)]: Download Complete."
    # echo "[$(date +%H:%M:%S)]: Extracting to Splunk Apps directory"
    # tar zxvf botsv2_data_set.tgz /opt/splunk/etc/apps
    ### FULL DATASET COMMENT BLOCK ENDS ###

    ### BOTSv2 COMMENT BLOCK ENDS ###

    # Add custom Macro definitions for ThreatHunting App
    cp /opt/DetectionLab/Vagrant/resources/splunk_server/macros.conf /opt/splunk/etc/apps/ThreatHunting/default/macros.conf
    # Fix Windows TA macros
    mkdir /opt/splunk/etc/apps/Splunk_TA_windows/local
    cp /opt/splunk/etc/apps/Splunk_TA_windows/default/macros.conf /opt/splunk/etc/apps/Splunk_TA_windows/local
    sed -i 's/wineventlog_windows/wineventlog/g' /opt/splunk/etc/apps/Splunk_TA_windows/local/macros.conf
    # Fix Force Directed App until 2.0.1 is released (https://answers.splunk.com/answers/668959/invalid-key-in-stanza-default-value-light.html#answer-669418)
    rm /opt/splunk/etc/apps/force_directed_viz/default/savedsearches.conf

    # Add a Splunk TCP input on port 9997
    echo -e "[splunktcp://9997]\nconnection_host = ip" >/opt/splunk/etc/apps/search/local/inputs.conf
    # Add props.conf and transforms.conf
    cp /opt/DetectionLab/Vagrant/resources/splunk_server/props.conf /opt/splunk/etc/apps/search/local/
    cp /opt/DetectionLab/Vagrant/resources/splunk_server/transforms.conf /opt/splunk/etc/apps/search/local/
    cp /opt/splunk/etc/system/default/limits.conf /opt/splunk/etc/system/local/limits.conf
    # Bump the memtable limits to allow for the ASN lookup table
    sed -i.bak 's/max_memtable_bytes = 10000000/max_memtable_bytes = 30000000/g' /opt/splunk/etc/system/local/limits.conf

    # Skip Splunk Tour and Change Password Dialog
    echo "[$(date +%H:%M:%S)]: Disabling the Splunk tour prompt..."
    touch /opt/splunk/etc/.ui_login
    mkdir -p /opt/splunk/etc/users/admin/search/local
    echo -e "[search-tour]\nviewed = 1" >/opt/splunk/etc/system/local/ui-tour.conf
    # Source: https://answers.splunk.com/answers/660728/how-to-disable-the-modal-pop-up-help-us-to-improve.html
    echo '[general]
render_version_messages = 0
hideInstrumentationOptInModal = 1
dismissedInstrumentationOptInVersion = 1
[general_default]
hideInstrumentationOptInModal = 1
showWhatsNew = 0
notification_python_3_impact = false' >/opt/splunk/etc/system/local/user-prefs.conf
    echo '[general]
render_version_messages = 0
hideInstrumentationOptInModal = 1
dismissedInstrumentationOptInVersion = 1
[general_default]
hideInstrumentationOptInModal = 1
showWhatsNew = 0
notification_python_3_impact = false' >/opt/splunk/etc/apps/user-prefs/local/user-prefs.conf
    # Disable the instrumentation popup
    echo -e "showOptInModal = 0\noptInVersionAcknowledged = 4" >>/opt/splunk/etc/apps/splunk_instrumentation/local/telemetry.conf

    # Enable SSL Login for Splunk
    echo -e "[settings]\nenableSplunkWebSSL = true" >/opt/splunk/etc/system/local/web.conf
    # Reboot Splunk to make changes take effect
    /opt/splunk/bin/splunk restart
    /opt/splunk/bin/splunk enable boot-start
    # Generate the ASN lookup table
    /opt/splunk/bin/splunk search "|asngen | outputlookup asn" -auth 'admin:changeme'
  fi
}

main() {
  install_prerequisites
  install_splunk
}

main
exit 0