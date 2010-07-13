#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/usb/USB.h>
#include <IOKit/usb/USBSpec.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <sys/stat.h>

#define RECOVERY 0x1281
#define DFU 0x1227
#define VENDOR_ID 0x05AC

#define REQUEST_COMMAND 0x40
#define REQUEST_FILE 0x21
#define REQUEST_STATUS 0xA1

#ifndef kUSBProductString
#define kUSBProductString "USB Product Name"
#endif

#ifndef kUSBSerialNumberString
#define kUSBSerialNumberString "USB Serial Number"
#endif

enum {
	kAppleVendorID		= 0x05AC
};

static int verbosity = 0;
//static int timeout=1000;
#define ibootutil_printf(...) { \
if(verbosity != 0) \
printf(__VA_ARGS__); \
}

struct iBootUSBConnection {
	io_service_t usbService;
	IOUSBDeviceInterface **deviceHandle;
	IOUSBInterfaceInterface **interfaceHandle;
	CFStringRef name, serial;
	UInt8 responsePipeRef;
	unsigned int idProduct, open;
};

typedef struct iBootUSBConnection *iBootUSBConnection;

void iDevice_print(iBootUSBConnection connection);
iBootUSBConnection iDevice_open(uint32_t productID);
void iDevice_close(iBootUSBConnection connection);
int iDevice_send_command(iBootUSBConnection connection, const char *command);
int iDevice_request_status(iBootUSBConnection connection, int flag);
int iDevice_send_file(iBootUSBConnection connection, const char *path);
void iDevice_reset(iBootUSBConnection connection);
void read_callback(void *refcon, IOReturn result, void *arg0);
int iDevice_usb_control_msg_exploit(iBootUSBConnection connection, const char *payload);