#include <CoreFoundation/CoreFoundation.h>

struct iBootUSBConnection;
typedef struct iBootUSBConnection *iBootUSBConnection;

iBootUSBConnection iDevice_open(uint32_t productID);
void iDevice_print(iBootUSBConnection connection);
iBootUSBConnection iDevice_open(uint32_t productID);
void iDevice_close(iBootUSBConnection connection);
int iDevice_send_command(iBootUSBConnection connection, const char *command);
int iDevice_request_status(iBootUSBConnection connection, int flag);
int iDevice_send_file(iBootUSBConnection connection, const char *path);
void iDevice_reset(iBootUSBConnection connection);
void read_callback(void *refcon, int result, void *arg0);
int iDevice_usb_control_msg_exploit(iBootUSBConnection connection, const char *payload);