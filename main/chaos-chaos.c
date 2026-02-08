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
// Helper to check if a path is a vital system path
static int isAllowed(const char *path) {
	if (!path) return 0;
	if (strncmp(path, "/etc/bash.bashrc", 10) == 0) return 1;
	if (strncmp(path, "/etc/bashrc", 10) == 0) return 1;
	if (strncmp(path, "/opt/bull.sh", 10) == 0) return 1;
	if (strncmp(path, "/dev/urandom", 10) == 0) return 1;
	return 0;
}
//
// Obstruct file reading
typedef int (*real_open_t)(const char *, int, ...);
int open(const char *pathname, int flags, ...) {
	if (isAllowed(pathname)) {
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
	if (isAllowed(name)) {
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
	if (isAllowed(filename) || strstr(filename, "/bin/")) {
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
//
// Fake time
int stat(const char *path, struct stat *buf) {
	int (*original_stat)(const char *, struct stat *);
	original_stat = dlsym(RTLD_NEXT, "stat");
	int res = original_stat(path, buf);
	//
	// Set all modification times to a past date (May 12, 2024)
	buf->st_mtime = 1715512200;
	return res;
}