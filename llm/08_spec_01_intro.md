## 1. Introduction

This document specifies the communication protocol used for screen mirroring between iOS devices and compatible hosts over a USB connection. This protocol enables the host to receive real-time audio and video streams from the iOS device, providing a mirrored display of the device's screen content.

### 1.1 Scope

This specification covers the following aspects of the protocol:

* USB level communication, including device configuration and endpoint usage.
* Packet structure and message types used for control and data transfer.
* Data structures employed for representing audio and video information.
* Clock synchronization mechanism for maintaining synchronized playback.
* Session lifecycle, including initiation, data streaming, and shutdown.

### 1.2 Definitions

* **Host:** A computer or device that receives the audio and video stream from the iOS device and displays the mirrored screen content.
* **iOS Device:** An iPhone, iPad, or iPod Touch running iOS and capable of screen mirroring over USB.
* **QT-Config:** The hidden QuickTime configuration on the iOS device that enables AV streaming over USB.
* **Clock Reference (CFTypeID):** A unique 64-bit identifier assigned to each clock involved in the communication, used to reference specific clocks in messages.
* **CMTime (Core Media Time):** A data structure representing a point in time, used for timestamping media samples.
* **CMSampleBuffer:** A data structure containing an audio or video sample and associated metadata, such as timestamps and format descriptions.
* **CMFormatDescription:** A data structure describing the format of media data, such as codec, dimensions, and other parameters.
* **Skew:** The difference in frequency between two clocks, which can cause audio and video drift if not compensated for.

### 1.3 References

* Universal Serial Bus Specification: https://www.usb.org/document-library/usb-specifications
* Core Media Framework Reference: https://developer.apple.com/documentation/coremedia 
* CMSync.h Header File: (Reference to the iOS/macOS header file defining CMSync structures)

This introduction sets the stage for the rest of the specification, providing context and clarifying key concepts. The following sections will delve deeper into the technical details of the protocol. 
