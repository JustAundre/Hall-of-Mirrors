#
# Display Manager
#
# LightDM
hash lightdm && (
	declare -x target_file=/etc/lightdm/lightdm.conf delimiter=\=
	#
	# Disable guest login
	reconfig allow-guest false
	#
	# Disable automatic login
	reconfig AutomaticLogin false
	#
	# Disable user enumeration
	reconfig greeter-show-manual-login true
	reconfig greeter-hide-users true
	#
	# Disable remote X server login
	reconfig xdmcp-enabled false
	#
	# Disable VNC/RDP access
	reconfig vnc-server-enabled false
)
#
# GDM3
hash gdm && (
	declare -x target_file=/etc/gdm/custom.conf delimiter=\=
	#
	# Disable automatic login
	reconfig AutomaticLoginEnable false
)
#
# SDDM
(
	declare -x target_file=/etc/sddm.conf
	
	# Disable automatic login
	reconfig User ''
	reconfig Session ''
	
	# Hide the user list
	reconfig HideUsers ''
	reconfig DisableDebug true
)