## 2. USB Level Communication

This section outlines the low-level USB communication details required for establishing and maintaining a screen mirroring session with an iOS device. 

### 2.1 Device Configuration

iOS devices present themselves on a host machine with multiple USB configurations. These configurations define the available interfaces and endpoints used for communication. The two configurations relevant for screen mirroring are:

* **Default Configuration (USBMux):**
    * This is the standard configuration active when an iOS device connects to a host. 
    * It primarily utilizes the `USBMux` protocol for managing various services, including file transfer and device management.
    * It exposes a single interface with two bulk endpoints, typically used for USBMux communication.
    * This configuration is identified by its interface subclass code: `0xFE`.

* **Hidden QuickTime Configuration (QT-Config):**
    * This configuration is not active by default and needs to be explicitly enabled for screen mirroring.
    * It exposes the necessary endpoints for high-bandwidth audio and video data transfer.
    * It provides an interface with four bulk endpoints: two for USBMux communication and two additional endpoints specifically for AV data.
    * This configuration is identified by its interface subclass code: `0x2A`.

### 2.2 Enabling the QuickTime Configuration

To enable the QT-Config and initiate a screen mirroring session, the host needs to send a specific control request to the device. This request triggers the device to switch configurations and re-enumerate on the USB bus. 

* **Control Request:**
    * **Request Type:** `0x40` (Vendor request, Host to Device)
    * **Request:** `0x52`
    * **Value:** `0x00`
    * **Index:** `0x02`
    * **Data:** No data payload.

* **Device Response:**
    * The device will momentarily disconnect from the host and reconnect with the QT-Config enabled.
    * The host operating system should automatically detect the new configuration and make the additional AV endpoints available.

### 2.3 Endpoints

Once the QT-Config is active, the following bulk endpoints become available for screen mirroring:

* **USBMux Endpoints:**
    * Two bulk endpoints are used for communication with the `usbmuxd` daemon running on the device, similar to the default configuration.
* **AV Data Endpoints:**
    * **Inbound Endpoint:** This endpoint is used by the device to send audio and video data to the host.
    * **Outbound Endpoint:** This endpoint is used by the host to send control messages and data requests to the device.

The host application needs to identify and claim these endpoints to establish a communication channel for screen mirroring.


This section provides the foundational understanding of how the iOS screen mirroring protocol leverages USB communication. The subsequent sections will delve into the details of the packet structure and message types used for exchanging data and control information over these endpoints.
