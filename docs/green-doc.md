# User Manual

## Notes

1. This document references the [Super] key (technical name), however, a majority will acknowledge it as the [Windows] key.

2. When typing sensitive information (*your password*), it may be redacted/completely hidden & you may *not* have the option to disable this. Regardless, rather than disable it, please adapt to it.

3. This document includes the host-name along-side the IP address of servers, you are to use the information from the `IP` column when the document refers to the "server IP you have chosen".

## Remote Login

### Server Info

| Host-name | IP | Purpose | Access Point(s) |
| -- | -- | -- | -- |
| WWW | `104.190.101.20` | Web server (front-end) | SSH, Browser |
| wms | `104.190.101.20` | Web server (back-end) | SSH |
| db | `104.190.101.40` | Database for managing user data & orders | SSH |

### Opening A Terminal

You'll likely find a terminal app just by opening your app menu (usually via the [Super] key) & typing in...

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

		- You can find a table of the server IPs & their corresponding hostnames in the (Server Info) section above

3. In your terminal, run the below—where `USERNAME` is your username, & `IP` is the server IP you have chosen.

```bash
ssh USERNAME@IP
```

4. Type your password when prompted as shown below

	* Your password ***will not*** appear as it is being typed; that is a feature, not a bug.

```txt
USERNAME@IP's password:
```

### Remote Desktop (Windows Servers)

0. Install Remina (Linux users only)
	- If you do not already have an RDP client on your Linux desktop, follow the instructions provided by the official Remmina developers [here](https://remmina.org/how-to-install-remmina/#flatpak)

1. Open an RDP client

	- For Windows, open your app menu (usually via the [Super] key), search for "Remote Desktop Connection", & click on the first result.

	- For Linux, open your app menu (usually via the [Super] key), & search for Remmina (or your own choice of an RDP client) & click on it.

2. Gather the necessary information for remote login
	You'll need the following:

	- Your username

	- Your password

	- The IP of the server you wish to remote into

	You can find a table of the server IPs & their corresponding hostnames in the (Server Info) section above

3. Enter your target IP in the horizontal text input bar which states something akin to "Computer" or "Remote IP".

4. Enter your username where prompted & continue.

5. Finally, once a connection is established, please enter your password & hit enter.

## Frontend Guidance

### Login/Sign-up

1. Go to http://104.190.101.20/

2. Press the "Login" button in the top right of the landing page.

3. Sign-in/Sign-up

	* Enter your credentials & hit [ENTER] if you are a returning user.

	* Press `Create an account` if you are a new user & enter the information you are asked for.

### Changing User Information

1. To change account information, click on your user-name in the top right.

2. Select/click on the text box with the label you wish you change (i.e. user-name, payment info, etc.)

3. Enter the new value for that piece of information.

4. Click [Submit] at the bottom of the card.

## Warehouse Management

### Point of Access

1. Follow the instructions for `SSH`-ing, but strictly for the `db` server;
- You can find the IP for the database server at sub-section "*Server Info*".

2. Once you're connected, you'll automatically drop into a MySQL prompt.
- Please see below for what it may look like:

```txt
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11282
Server version: 5.7.44-0ubuntu0.16.04.1+esm1 (Ubuntu)

Copyright (c) 2000, 2023, Oracle &/or its affiliates.

Oracle is a registered trademark of Oracle Corporation &/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

### How to SQL/Change Stock Information

1. Select the database `iseage_db` as shown below, using the `use iseage_db;` command
- **The semicon (`;`) at the end of the command not optional.**

```txt
mysql> use iseage_db;
Reading table information for completion of table & column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql>
```

2. To see the current itemset, descriptions of each item, their prices & stored quantities,
	Run the command `select * from items;`.

3. To update values, is a bit complex—however,

	* You will type out `UPDATE items` & press enter. (NO SEMICOLON)

	* Then, type out `SET column = 'new value'` where column is the
		`column` of the value you want to change & `new value` is the new value for your target
		(no semicolon ONLY if you *wish to set the entire column to that value*).

	* Finally, if you **do not wish to set the entire column to 1 value,** you must type `WHERE id = number;`
		where `number` is the target ID number of the item you wish to modify (semicolon included).

4. To put it simply:

	* The 2nd line indicates the column & new value

	* The 3rd indicates the row.

	* The column & row are combined to make a selection on *1 target* instead of every item in a column.

5. Below will be a demonstration:

Here is a table, as a result of my usage of `select * from items;`.
```js
+----+--------------------+---------------------------------+-------+----------+
| id | description        | name                            | price | quantity |
+----+--------------------+---------------------------------+-------+----------+
|  1 | 6-pack             | Fahrenheit Radberry Rush        |  2.59 |      150 |
|  2 | Individual bottles | Fahrenheit Watermelon           |  8.50 |      125 |
|  3 | Drink mix          | 0-Degrees Fahrenheit (Lemonade) |  4.50 |      110 |
|  4 | 1-gallon           | Fahrenheit Iced Tea             |  2.37 |       80 |
+----+--------------------+---------------------------------+-------+----------+
```

To compose my command to change the price of the `Fahrenheit Watermelon`...

* My `column` will be `price`.

* My `ID/Number` will be `2`.

* My `new value` will be... `3.50`.

My final command will be:

```sql
UPDATE items
SET price = '3.50'
WHERE id = '2';
```

6. Let's practice safety.

If my final command is the below:

```sql
UPDATE items
SET price = '3.50'
WHERE id = '2';
```

Then I should run the below to ensure the correct item is being selected:

```sql
SELECT * FROM items WHERE id = '2';
```

You just append the `WHERE` statement to the end of the handy `SELECT` statement we learned earlier.
