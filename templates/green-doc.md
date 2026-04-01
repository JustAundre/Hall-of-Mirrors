# User Manual

## Notes

1. This document references the [Super] key (technical name), however, a majority will acknowledge it as the [Windows] key.

2. When typing sensitive information (*your password*), it may be redacted/completely hidden and you may *not* have the option to disable this. Regardless, rather than disable it, please adapt to it.

3. This document includes the hostname along-side the IP address of servers, you are to use the information from the `IP` column when the document refers to the "server IP you have chosen".

## Remote Login Software

### Server Info

| Hostname | IP | Purpose | Access Point |
| --- | --- | --- | --- |
| www | `36.3.5.40` | Web server (frontend) | SSH |
| db | `36.3.5.50` | Database for storing user data and allowing the frontend to interface with such data (backend) | SSH |

### Opening A Terminal

You'll likely find a terminal app just by opening your app menu (usually via the [Super] key) and typing in...
	- Terminal (for Linux)
	- PowerShell (for modern Windows)
Press [ENTER] once the terminal app has been highlighted/selected, or simply click on it.

### SSH (Linux Servers)

1. Open a terminal.

2. Gather the necessary information for remote login
	You'll need the following:
	- Your username
	- Your password
	- The IP of the server you wish to remote into
	You can find a table of the server IPs and their corresponding hostnames in the (Server Info) section above

3. In your terminal, run the below--where `USERNAME` is your username, and `IP` is the server IP you have chosen.
```bash
ssh USERNAME@IP
```

4. Type your password when prompted (example of prompt is shown below):
```txt
USERNAME@IP's password:
```

### Remote Desktop (Windows Servers)

0. Install Remina (Linux users only)
	- If you do not already have an RDP client on your Linux desktop, follow the instructions provided by the official Remmina developers [here](https://remmina.org/how-to-install-remmina/#flatpak)

1. Open an RDP client
	- For Windows, open your app menu (usually via the [Super] key), search for "Remote Desktop Connection", and click on the first result.
	- For Linux, open your app menu (usually via the [Super] key), and search for Remmina (or your own choice of an RDP client) and click on it.

2. Gather the necessary information for remote login
	You'll need the following:
	- Your username
	- Your password
	- The IP of the server you wish to remote into
	You can find a table of the server IPs and their corresponding hostnames in the (Server Info) section above

3. Enter your target IP in the horizontal text input bar which states something akin to "Computer" or "Remote IP".

4. Enter your username where prompted and continue.

5. Finally, once a connection is established, please enter your password and hit enter.

## Website Guidance

### Frontend -- Login

1. Go to http://36.3.5.40/

2. Press the "Login" button in the top right of the landing page.

3. Enter your credentials and hit [ENTER].

### Frontend -- Changing User Information

1. To change personal information, press on the button containing your username (in the same location where the login button formerly was)

2. Select/click on the text box with the label you wish you change (i.e. Username, Date of Birth, etc.)

3. Enter the new value that piece of information

4. Click the "Submit" button at the bottom of the card.