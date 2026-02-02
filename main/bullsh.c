#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
//
// SHA512 password hash
const char* passHash = "d8e6e9a45f9d5cc17fc41abf91919728088f068cea0ddb788a4cf10c303dfe90765a641915a111935756751e7a4d7add1587ff28e05b878d5c5fcb0c51b96c6a";
//
// Log file for failed login attempts
const char* logFile = "/var/tmp/install.log";
//
// Whitelisted users ( i.e. {"root", "john.doe", "jane", NULL} -- KEEP THE NULL.)
const char* sysAdmins[] = {"cdc", NULL};
//
// Function to pass off into real shell
void passOff() {
	char *args[] = {"/usr/bin/bash", "-i", NULL};
	execv("/usr/bin/bash", args);
	perror("execv");
	exit(1);
}
//
// Function to handle the int signal
void handleSigInt(int sig) {
	char hostname[1024];
	gethostname(hostname, sizeof(hostname));
	//
	// Reset colors/visibility just in case
	printf("\033[0m\nroot@%s# ", hostname);
	fflush(stdout);
}
//
// Function to hash input
void hashInput(const char* input, char* output) {
	// Write the input to a file
	FILE *hash = fopen("/tmp/hashIn.txt", "w");
	if (hash == NULL) return; // Basic error check
	fprintf(hash, "%s", input);
	fclose(hash);
	//
	// Hash the file and store the result in another file
	system("sha512sum /tmp/hashIn.txt | awk '{print $1}' > /tmp/hashOut.txt");
	//
	// READ the hash back into the 'output' buffer
	FILE *res = fopen("/tmp/hashOut.txt", "r");
	if (res != NULL) {
		// Read 128 characters (the SHA512 hex string)
		if (fgets(output, 129, res) != NULL) {
			// Remove any trailing newline that might be there
			output[strcspn(output, "\n")] = 0;
		}
		fclose(res);
	}
	//
	// Cleanup
	remove("/tmp/hashIn.txt");
	remove("/tmp/hashOut.txt");
}
//
// Function to log failed attempts
void logAttempt(const char* attempt) {
	// Descrete false name for the log file
	FILE *f = fopen(logFile, "a");
	if (f == NULL) return;
	//
	// Get metadata
	char *user = getenv("USER");
	char *connInfo = getenv("SSH_CONNECTION");
	//
	// Backups
	if (user == NULL) {
		user = "Anonymous";
	}
	if (connInfo == NULL) {
		connInfo = "Local";
	}
	//
	// Extract just the IP from the SSH string
	char connection[128];
	strncpy(connection, connInfo, sizeof(connection));
	char *ip = strtok(connection, " "); 
	//
	// Get current time
	time_t now = time(NULL);
	char *timestamp = ctime(&now);
	timestamp[strcspn(timestamp, "\n")] = 0;
	//
	// Send to the file
	fprintf(f, "[%s] User: %s | IP: %s | Attempt: %s\n", timestamp, user, ip, attempt);
	//
	// Cleanly save and close the log file
	fclose(f);
}
//
// Main Logic
// The meat of the shell--make them think they're root.
int main() {
	char input[128];
	char inputHash[129];
	char hostname[1024];
	gethostname(hostname, sizeof(hostname));
	signal(SIGINT, handleSigInt);
	//
	// Pass off whitelisted sysadmins to the real shell immediately
	char *currentUser = getenv("USER");
	for (int i = 0; sysAdmins[i] != NULL; i++) {
		if (strcmp(currentUser, sysAdmins[i]) == 0) {
			passOff();
			break;
		}
	}
	while (1) {
		// Fake root access :3
		printf("root@%s# ", hostname);
		fflush(stdout);
		if (fgets(input, sizeof(input), stdin) == NULL) {
			printf("\033[0m");
			break;
		}
		//
		// Parses the input
		input[strcspn(input, "\n")] = 0;
		if (strlen(input) == 0) continue;
		hashInput(input, inputHash);
		//
		// If input is password, let them in; else, kick em out.
		if (strcmp(inputHash, passHash) == 0) {

		} else {
			// Log failed attempts
			logAttempt(input);
			printf("-bash: %s: Permission denied\n", input);
			//
			// Force exit after failure
			printf("Connection to %s closed.\n", hostname);
			exit(1); 
		}
	}
	return 0;
}