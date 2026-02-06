#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <dirent.h>
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