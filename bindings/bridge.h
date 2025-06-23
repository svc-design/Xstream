#ifndef BRIDGE_H
#define BRIDGE_H

#include <stdint.h>

char* WriteConfigFiles(const char* xrayPath,
                       const char* xrayContent,
                       const char* servicePath,
                       const char* serviceContent,
                       const char* vpnPath,
                       const char* vpnContent,
                       const char* password);

char* StartNodeService(const char* name);
char* StopNodeService(const char* name);
int32_t CheckNodeStatus(const char* name);
char* CreateWindowsService(const char* name,
                           const char* execPath,
                           const char* configPath);
char* PerformAction(const char* action, const char* password);
int32_t IsXrayDownloading(void);
void FreeCString(char* str);

#endif // BRIDGE_H
