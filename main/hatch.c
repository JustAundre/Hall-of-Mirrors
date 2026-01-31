#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main() {
	char *pass = getpass("bash-5.3$ ");
	char command[256];
	
	snprintf(command, sizeof(command), "echo '%s' | sha512sum | cut -d' ' -f1", pass);

	FILE *fp = popen(command, "r");
	if (fp == NULL) {
		perror("popen");
		return 1;
	}

	char output[129]; // SHA512 is 128 hex chars
	if (fgets(output, 129, fp) != NULL) {
		const char* TARGET = "3b143e352086df25e948560dffbe12d266e6a44de9162c8e19b6688868eb36131831ce197ce7d5acfa86cc50dd2a4c0ebbf86614d05e5e52da713a79a1fadd28";
		char *cleanargs[] = { "/usr/bin/env", "-i", "/usr/bin/bash", NULL };
		char *cleanenv[] = { NULL };

		if (strncmp(output, TARGET, 128) == 0) {
			printf("\033[1;32m...\033[0m\n");
			execve("/usr/bin/env", cleanargs, cleanenv);
		} else {
			printf("");
		}
	}

	pclose(fp);
	return 0;
}