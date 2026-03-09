#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <time.h>
#include <stdlib.h>
#include <pwd.h>
//
// Helper for checking blocked paths
static int isDisallowed(const char *path) {
	if (!path) return 0;
	if (strncmp(path, "/proc", 5) == 0) return 0;
	if (strncmp(path, "/etc", 4) == 0) return 0;
	if (strncmp(path, "/root", 5) == 0) return 0;
	return 1;
}
//
// Obstruct file reading
typedef int (*real_open_t)(const char *, int, ...);
int open(const char *pathname, int flags, ...) {
	if (isDisallowed(pathname)) {
		real_open_t real_open = (real_open_t)dlsym(RTLD_NEXT, "open");
		return real_open(pathname, flags);
	}
	errno = EACCES;
	return -1;
}
//
// Obstruct file enumeration
typedef DIR* (*real_opendir_t)(const char *);
DIR *opendir(const char *name) {
	if (isDisallowed(name)) {
		real_opendir_t real_opendir = (real_opendir_t)dlsym(RTLD_NEXT, "opendir");
		return real_opendir(name);
	}
	errno = EACCES;
	return NULL;
}
//
// Obstruct directory navigation
int chdir(const char *path) {
	errno = EACCES;
	return -1;
}
//
// Obstruct file execution
typedef int (*real_execve_t)(const char *, char *const[], char *const[]);
int execve(const char *filename, char *const argv[], char *const envp[]) {
	if (isDisallowed(filename)) {
		real_execve_t real_execve = (real_execve_t)dlsym(RTLD_NEXT, "execve");
		return real_execve(filename, argv, envp);
	}
	errno = EACCES;
	return -1;
}
//
// Intercept calls for IDs
uid_t getuid(void) { return 0; }
uid_t geteuid(void) { return 0; }
gid_t getgid(void) { return 0; }
gid_t getegid(void) { return 0; }
struct passwd *getpwuid(uid_t uid) {
	static struct passwd fake;
	fake.pw_name = "root";
	fake.pw_passwd = "x";
	fake.pw_uid = 0;
	fake.pw_gid = 0;
	fake.pw_gecos = "root";
	fake.pw_dir = "/root";
	fake.pw_shell = "/bin/bash";
	return &fake;
}