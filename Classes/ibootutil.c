#include "ibootutil.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/usb/USB.h>
#include <IOKit/usb/USBSpec.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <sys/stat.h>

struct iBootUSBConnection {
	io_service_t usbService;
	IOUSBDeviceInterface **deviceHandle;
	IOUSBInterfaceInterface **interfaceHandle;
	CFStringRef name, serial;
	UInt8 responsePipeRef;
	unsigned int idProduct, open;
};

#define RECOVERY 0x1281
#define DFU 0x1227

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

void iDevice_print(iBootUSBConnection connection) {
	if(connection != NULL && verbosity != 0) {
		if(connection->name && connection->serial) {
			CFShow(connection->name);
			CFShow(connection->serial);
		}
	}
}

iBootUSBConnection iDevice_open(uint32_t productID) {
	CFMutableDictionaryRef match = IOServiceMatching(kIOUSBDeviceClassName);
	if(match == NULL) {
		return NULL;
	}
	
	uint32_t vendorID = kAppleVendorID;
	CFNumberRef idVendor = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID);
	CFNumberRef idProduct = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &productID);
	
	CFDictionarySetValue(match, CFSTR(kUSBVendorID), idVendor);
	CFDictionarySetValue(match, CFSTR(kUSBProductID), idProduct);
	
	CFRelease(idVendor);
	CFRelease(idProduct);
	
	io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, match);
	if(!service) {
		return NULL;
	}
	
	IOCFPlugInInterface **pluginInterface;
	IOUSBDeviceInterface **deviceHandle;
	IOUSBInterfaceInterface **interfaceHandle;
	
	SInt32 score;
	if(IOCreatePlugInInterfaceForService(service, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score) != 0) {
		IOObjectRelease(service);
		return NULL;
	}
	
	if((*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
										  (LPVOID*)&deviceHandle) != 0) {
		IOObjectRelease(service);
		return NULL;
	}
	
	(*pluginInterface)->Release(pluginInterface);
	
	if((*deviceHandle)->USBDeviceOpen(deviceHandle) != 0) { 
		IOObjectRelease(service);
		(*deviceHandle)->Release(deviceHandle);
		return NULL;
	}
	
	// Claim interface -- PLEASE SOMEONE HELP WITH RESPONSE
	
	if((*deviceHandle)->SetConfiguration(deviceHandle, 1) != 0) {
		IOObjectRelease(service);
		(*deviceHandle)->USBDeviceClose(deviceHandle);
		(*deviceHandle)->Release(deviceHandle);
		return NULL;
	}
	
	io_iterator_t iterator;
	IOUSBFindInterfaceRequest interfaceRequest;
	
	interfaceRequest.bAlternateSetting 
	= interfaceRequest.bInterfaceClass 
	= interfaceRequest.bInterfaceProtocol 
	= interfaceRequest.bInterfaceSubClass 
	= kIOUSBFindInterfaceDontCare;
	
	if((*deviceHandle)->CreateInterfaceIterator(deviceHandle, &interfaceRequest, &iterator) != 0) {
		IOObjectRelease(service);
		(*deviceHandle)->USBDeviceClose(deviceHandle);
		(*deviceHandle)->Release(deviceHandle);
		return NULL;
	}
	
	io_service_t usbInterface;
	UInt8 found_interface = 0, index = 0;
	while(usbInterface = IOIteratorNext(iterator)) {
		if(index < 1) {
			index++;
			continue;
		}
		
		IOCFPlugInInterface **iodev;
		
		SInt32 score;
		if(IOCreatePlugInInterfaceForService(usbInterface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &iodev, &score) != 0) {
			IOObjectRelease(usbInterface);
			continue;
		}
		
		if((*iodev)->QueryInterface(iodev, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID)&interfaceHandle) != 0) {
			(*iodev)->Release(iodev);
			IOObjectRelease(usbInterface);
			continue;
		}
		(*iodev)->Release(iodev);
		
		if((*interfaceHandle)->USBInterfaceOpen(interfaceHandle) != 0) {
			(*interfaceHandle)->Release(interfaceHandle);
			IOObjectRelease(usbInterface);
			continue;
		}
		
		UInt8 pipes;
		(*interfaceHandle)->SetAlternateInterface(interfaceHandle, 1);
		(*interfaceHandle)->GetNumEndpoints(interfaceHandle, &pipes);
		
		for(UInt8 i=0;i<=pipes;++i) {
			UInt8 ind = i;
			UInt8 direction, number, transferType, interval;
			UInt16 maxPacketSize;
			
			(*interfaceHandle)->GetPipeProperties(interfaceHandle, ind, &direction, &number, &transferType, &maxPacketSize, &interval);
			if(transferType == kUSBBulk && direction == kUSBIn) {
				found_interface = i;
				IOObjectRelease(usbInterface);
				break;
			}
		}
		
		IOObjectRelease(usbInterface);
	}
	IOObjectRelease(iterator);
	
	CFStringRef productName = IORegistryEntryCreateCFProperty(service, CFSTR(kUSBProductString), kCFAllocatorDefault, 0);
	CFStringRef productSerial = IORegistryEntryCreateCFProperty(service, CFSTR(kUSBSerialNumberString), kCFAllocatorDefault, 0);
	
	iBootUSBConnection connection = malloc(sizeof(struct iBootUSBConnection));
	memset(connection, '\0', sizeof(struct iBootUSBConnection));
	
	connection->interfaceHandle = interfaceHandle;
	connection->usbService = service;
	connection->deviceHandle = deviceHandle;	
	connection->name = productName;
	connection->serial = productSerial;
	connection->idProduct = productID;
	connection->open = 1;
	connection->responsePipeRef = found_interface;
	
	iDevice_print(connection);
	
	return connection;
}

void iDevice_close(iBootUSBConnection connection) {
	if(connection != NULL) {
		if(connection->deviceHandle) (*connection->deviceHandle)->USBDeviceClose(connection->deviceHandle);
		if(connection->deviceHandle) (*connection->deviceHandle)->Release(connection->deviceHandle);
		if(connection->interfaceHandle) (*connection->interfaceHandle)->USBInterfaceClose(connection->interfaceHandle);
		if(connection->interfaceHandle) (*connection->interfaceHandle)->Release(connection->interfaceHandle);
		if(connection->name) CFRelease(connection->name);
		if(connection->serial) CFRelease(connection->serial);
		if(connection->usbService) IOObjectRelease(connection->usbService);
		connection->open = 0;
		
		free(connection);
	}
}

int iDevice_send_command(iBootUSBConnection connection, const char *command) {
	if(connection == NULL || command == NULL)
		return -1;
	
	IOUSBDevRequest request;
	request.bmRequestType = REQUEST_COMMAND;
	request.bRequest = 0x0;
	request.wValue = 0x0;
	request.wIndex = 0x0;
	request.wLength = (UInt16)(strlen(command)+1);
	request.pData = (void *)command;
	request.wLenDone = 0x0;
	
	if((*connection->deviceHandle)->DeviceRequest(connection->deviceHandle, &request) != kIOReturnSuccess) {
		if(strcmp(command, "reboot") != 0) {
			ibootutil_printf("Error sending command\n");
		} else {
			printf("Rebooting device...\n");
			iDevice_close(connection);
			exit(0);
		}
		
		return -1;
	} 
	
	return 0;
}

int iDevice_request_status(iBootUSBConnection connection, int flag) {
	if(connection == NULL)
		return -1;
	
	IOUSBDevRequest status_request;
	char response[6];
	
	status_request.bmRequestType = REQUEST_STATUS;
	status_request.bRequest = 0x3;
	status_request.wValue = 0x0;
	status_request.wIndex = 0x0;
	status_request.wLength = 0x6;
	status_request.pData = (void *)response;
	status_request.wLenDone = 0x0;
	
	if((*connection->deviceHandle)->DeviceRequest(connection->deviceHandle, &status_request) != kIOReturnSuccess) {
		printf("Error: couldn't receive status\n");
		return -1;
	}
	
	if(response[4] != flag) {
		printf("Error: invalid status response\n");
		return -1;
	}
	
	return 0;
}

int iDevice_send_file(iBootUSBConnection connection, const char *path) {
	if(connection == NULL || path == NULL)
		return -1;
	
	unsigned char *buf;
	unsigned int packet_size = 0x800;
	struct stat check;
	
	if(stat(path, &check) != 0) {
		printf("File doesn't exist: %s\n", path);
		return -1;
	}
	
	buf = malloc(check.st_size);
	memset(buf, '\0', check.st_size);
	
	FILE *file = fopen(path, "r");
	if(file == NULL) {
		printf("Couldn't open file: %s\n", path);
		return -1;
	}
	
	if(fread((void *)buf, check.st_size, 1, file) == 0) {
		printf("Couldn't create buffer\n");
		fclose(file);
		free(buf);
		return -1;
	}
	
	fclose(file);
	
	unsigned int packets, current;
	packets = (check.st_size / packet_size);
	if(check.st_size % packet_size) {
		packets++;
	}
	
	for(current = 0; current < packets; ++current) {
		int size = (current + 1 < packets ? packet_size : (check.st_size % packet_size));
		
		IOUSBDevRequest file_request;
		
		file_request.bmRequestType = REQUEST_FILE;
		file_request.bRequest = 0x1;
		file_request.wValue = current;
		file_request.wIndex = 0x0;
		file_request.wLength = (UInt16)size;
		file_request.pData = (void *)&buf[current * packet_size];
		file_request.wLenDone = 0x0;
		
		if((*connection->deviceHandle)->DeviceRequest(connection->deviceHandle, &file_request) != kIOReturnSuccess) {
			ibootutil_printf("Error: couldn't send packet %d\n", current + 1);
			free(buf);
			return -1;
		}
		
		if(iDevice_request_status(connection, 5) != 0) {
			free(buf);
			return -1;
		}
	}
	
	IOUSBDevRequest checkup;
	checkup.bmRequestType = REQUEST_FILE;
	checkup.bRequest = 0x1;
	checkup.wValue = current;
	checkup.wIndex = 0x0;
	checkup.wLength = 0x0;
	checkup.pData = buf;
	checkup.wLenDone = 0x0;
	
	(*connection->deviceHandle)->DeviceRequest(connection->deviceHandle, &checkup);
	
	for(current = 6; current < 8; ++current) {
		if(iDevice_request_status(connection, current) != 0) {
			free(buf);
			return -1;
		}
	}
	
	free(buf);
	printf("Sent file\n");
	
	return 0;
}

void iDevice_reset(iBootUSBConnection connection) {
	if(connection == NULL) 
		return;
	
	(*connection->deviceHandle)->ResetDevice(connection->deviceHandle);
	iDevice_close(connection);
}

void read_callback(void *refcon, IOReturn result, void *arg0) {
	for(int i=0;i<0x800;++i) {
		printf("%c", ((char *)refcon)[i]);
	}
	for(int i=0;i<0x800;++i) {
		printf("%c", ((char *)arg0)[i]);
	}
}

int iDevice_usb_control_msg_exploit(iBootUSBConnection connection, const char *payload) {
	if(connection == NULL || !connection->open) {
		printf("device isn't open\n");
		return -1;
	}
	
	if(iDevice_send_file(connection, payload) != 0) {
		printf("couldn't send payload\n");
		return -1;
	}
	
	IOUSBDevRequest checkup;
	checkup.bmRequestType = REQUEST_FILE;
	checkup.bRequest = 0x2;
	checkup.wValue = 0x0;
	checkup.wIndex = 0x0;
	checkup.wLength = 0x0;
	checkup.pData = 0x0;
	checkup.wLenDone = 0x0;
	
	if((*connection->deviceHandle)->DeviceRequest(connection->deviceHandle, &checkup) != 0) {
		printf("couldn't send exploit message\n");
		return -1;
	}
	
	return 0;
}