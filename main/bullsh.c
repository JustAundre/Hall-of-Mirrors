#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <openssl/evp.h>
//
// SHA512 password hash
const char* password_hash = "d8e6e9a45f9d5cc17fc41abf91919728088f068cea0ddb788a4cf10c303dfe90765a641915a111935756751e7a4d7add1587ff28e05b878d5c5fcb0c51b96c6a";
//
// A function to handle the int signal
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
	unsigned char hash[EVP_MAX_MD_SIZE];
	unsigned int length;
	EVP_MD_CTX* context = EVP_MD_CTX_new();
	EVP_DigestInit_ex(context, EVP_sha512(), NULL);
	EVP_DigestUpdate(context, input, strlen(input));
	EVP_DigestFinal_ex(context, hash, &length);
	EVP_MD_CTX_free(context);
	for(unsigned int i = 0; i < length; i++)
		sprintf(output + (i * 2), "%02x", hash[i]);
}
//
// Function to log failed attempts
void logAttempt(const char* attempt) {
	// Descrete false name for the log file
	FILE *f = fopen("/var/tmp/install.log", "a");
	if (f == NULL) return;
	//
	// Get metadata
	char *user = getenv("USER");
	char *ssh_info = getenv("SSH_CONNECTION");
	//
	// Default values if not running via SSH
	if (user == NULL) user = "unknown";
	if (ssh_info == NULL) ssh_info = "local_console";
	//
	// Extract just the IP from the SSH string
	char connection[128];
	strncpy(connection, ssh_info, sizeof(connection));
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
// The meat of the shell--make them think they're root.
int main() {
	char input[128];
	char hashed_input[129];
	char hostname[1024];

	gethostname(hostname, sizeof(hostname));
	signal(SIGINT, handleSigInt);

	while (1) {
		printf("root@%s# ", hostname);
		fflush(stdout);

		if (fgets(input, sizeof(input), stdin) == NULL) {
			printf("\033[0m");
			break;
		}
		//
		// \033[0m Resets text to normal
		printf("\033[0m");

		input[strcspn(input, "\n")] = 0;
		if (strlen(input) == 0) continue;

		hashInput(input, hashed_input);

		if (strcmp(hashed_input, password_hash) == 0) {
			printf("...\n");
			char *args[] = {"/bin/bash", NULL};
			execv("/bin/bash", args);
			perror("execv");
			exit(1);
		} else {
			logAttempt(input); // Log failed attempts
			printf("-bash: %s: Permission denied\n", input);
		}
	}
	return 0;
}