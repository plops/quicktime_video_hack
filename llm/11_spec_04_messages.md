## 4. Message Types:

This section provides detailed information about the different message types used in the iOS screen mirroring protocol. Each message type is categorized as either **PING**, **SYNC**, **RPLY**, or **ASYN**, indicating its role in the communication.

### 4.1 PING Packet:

* **Purpose:** The PING packet serves as a simple handshake mechanism to establish and maintain the connection between the host and the iOS device.
* **Structure:**
    * **Length:** 16 bytes
    * **Magic Marker:** `PING` (0x70696E67)
    * **Header:**  8 bytes, fixed value (0x0000000100000000)
* **Exchange:**
    * The device initiates the communication by sending a PING packet.
    * The host, upon receiving the PING, immediately responds with an identical PING packet.
    * The absence of further PING packets indicates a connection issue.

### 4.2 SYNC Packets:

SYNC packets are used for clock synchronization and require a corresponding RPLY (reply) packet from the host. They generally carry a Correlation ID for matching requests and replies.

#### 4.2.1 CWPA (Clock Walltime Anchor for Audio):

* **Purpose:**  Initiates the audio stream and establishes a common reference point for the audio clocks of the host and device.
* **Request Format:**
    * **Length:** 36 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** Empty CFTypeID (0x1)
    * **Message Type:** `CWPA` (0x63777061)
    * **Correlation ID:** 8 byte unique identifier
    * **Device Audio Clock Ref:** 8 byte CFTypeID identifying the device's audio clock
* **Reply Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Local Audio Clock Ref:** 8 byte CFTypeID identifying the host's newly created audio clock

#### 4.2.2 AFMT (Audio Format):

* **Purpose:** Conveys information about the audio format used by the device.
* **Request Format:**
    * **Length:** 68 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:**  8 byte CFTypeID referencing the host's audio clock (received in CWPA reply)
    * **Message Type:** `AFMT` (0x61666D74)
    * **Correlation ID:** 8 byte unique identifier
    * **Audio Format Data:**  48 bytes containing an AudioStreamBasicDescription struct (see CoreAudio documentation for details)
* **Reply Format:**
    * **Length:** 62 bytes 
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Payload:**  A dictionary with a single entry: `{"Error": NSNumberUint32(0)}` indicating success.

#### 4.2.3 CVRP (Clock and Video Rate Parameters):

* **Purpose:** Establishes a common reference for the video clocks and sets up the video data request mechanism.
* **Request Format:**
    * **Length:** Variable, typically around 649 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** Empty CFTypeID (0x1)
    * **Message Type:** `CVRP` (0x63767270)
    * **Correlation ID:** 8 byte unique identifier
    * **Device Video Clock Ref:** 8 byte CFTypeID identifying the device's video clock
    * **Payload:** A StringKeyDict containing:
        * `FormatDescription`:  CMFormatDescription with video format details (codec, dimensions, SPS, PPS).
        * Additional parameters related to video buffering and timing.
* **Reply Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Local Video Clock Ref:** 8 byte CFTypeID identifying the host's newly created video clock

#### 4.2.4 CLOK (Create Clock):

* **Purpose:**  Requests the host to create a new clock, often used for timing subsequent SYNC packets like TIME.
* **Request Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** 8 byte CFTypeID (purpose unknown)
    * **Message Type:** `CLOK` (0x636C6F6B)
    * **Correlation ID:** 8 byte unique identifier
* **Reply Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Newly Created Clock Ref:**  8 byte CFTypeID identifying the new clock created by the host

#### 4.2.5 TIME:

* **Purpose:**  Used to synchronize the time between the device's and host's clocks.
* **Request Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** 8 byte CFTypeID identifying the clock to synchronize 
    * **Message Type:** `TIME` (0x74696D65)
    * **Correlation ID:** 8 byte unique identifier
* **Reply Format:**
    * **Length:** 44 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **CMTime:** 24 bytes containing the current CMTime of the specified clock on the host.

#### 4.2.6 SKEW:

* **Purpose:** Informs the device about the clock skew (frequency difference) of the audio clock, enabling drift adjustments.
* **Request Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** 8 byte CFTypeID referencing the host's audio clock 
    * **Message Type:** `SKEW` (0x736B6577)
    * **Correlation ID:** 8 byte unique identifier
* **Reply Format:**
    * **Length:** 24 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Skew Value:** 8 bytes containing a double-precision floating-point number representing the calculated skew value.

#### 4.2.7 OG:

* **Purpose:**  The exact purpose of the OG packet is currently unknown.
* **Request Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** 8 byte CFTypeID (purpose unknown)
    * **Message Type:** `OG!` (0x20216F67)
    * **Correlation ID:** 8 byte unique identifier
    * **Unknown Data:** 4 bytes 
* **Reply Format:**
    * **Length:** 24 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Payload:** 8 bytes, all zeros 

#### 4.2.8 STOP:

* **Purpose:**  Signals the host to stop a specific clock.
* **Request Format:**
    * **Length:** 28 bytes
    * **Magic Marker:** `SYNC` (0x73796E63)
    * **Clock Ref:** 8 byte CFTypeID of the clock to stop
    * **Message Type:** `STOP` (0x73746F70)
    * **Correlation ID:** 8 byte unique identifier
* **Reply Format:**
    * **Length:** 24 bytes
    * **Magic Marker:** `RPLY` (0x72706C79)
    * **Correlation ID:** Matching the request Correlation ID
    * **Payload:** 8 bytes, all zeros

### 4.3 RPLY Packets:

RPLY packets are replies to SYNC packets sent by the host. Their structure is generally:

* **Length:** Variable, depending on the payload.
* **Magic Marker:** `RPLY` (0x72706C79)
* **Correlation ID:** Matching the corresponding SYNC packet's Correlation ID.
* **Payload:**  Variable, containing the response data as specified by the SYNC message type.

### 4.4 ASYN Packets:

ASYN packets carry various informational and control messages and do not require a response from the host. 

#### 4.4.1 SPRP (Set Property):

* **Purpose:**  Sets properties related to the video stream.
* **Packet Format:**
    * **Length:** Variable
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID referencing the video clock 
    * **Message Type:** `SPRP` (0x73707270)
    * **Payload:**  A StringKeyEntry containing the property name and value. 
        * Common properties include:
            * `ObeyEmptyMediaMarkers`: Boolean, typically set to `true`.
            * `RenderEmptyMedia`: Boolean, typically set to `false`.

#### 4.4.2 SRAT (Set Time Rate and Anchor):

* **Purpose:** Potentially related to controlling the playback rate, similar to AVPlayer.setRate().
* **Packet Format:**
    * **Length:**  49 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID 
    * **Message Type:** `SRAT` (0x73726174)
    * **Payload:** 
        * `Rate1`: 4 bytes, float32
        * `Rate2`: 4 bytes, float32
        * `CMTime`: 24 bytes, specifying a time

#### 4.4.3 TBAS (TimeBase):

* **Purpose:**  Informs the host about a new TimeBase, possibly related to CMTimeBase objects.
* **Packet Format:**
    * **Length:** 24 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:**  8 byte CFTypeID
    * **Message Type:** `TBAS` (0x74626173)
    * **Unknown Clock Ref:** 8 bytes, CFTypeID 

#### 4.4.4 TJMP (Time Jump):

* **Purpose:**  Notifies the host about a time jump on a TimeBase, possibly indicating a seek or discontinuity.
* **Packet Format:**
    * **Length:** 72 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID 
    * **Message Type:** `TJMP` (0x706D6A74)
    * **Unknown Data:** 56 bytes

#### 4.4.5 FEED:

* **Purpose:**  Carries video data from the device to the host.
* **Packet Format:**
    * **Length:** Variable, depends on video frame size
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID referencing the host's video clock (received in CVRP reply)
    * **Message Type:** `FEED` (0x66656564)
    * **Payload:** A CMSampleBuffer containing:
        * `OutputPresentationTimestamp`: CMTime indicating the presentation time of the video frame.
        * `FormatDescription`: CMFormatDescription with video format details (may be absent if already sent).
        * `SampleData`: Raw H.264 NAL units representing the video frame.

#### 4.4.6 EAT!:

* **Purpose:** Carries audio data from the device to the host.
* **Packet Format:**
    * **Length:** Variable, depends on audio buffer size.
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID referencing the host's audio clock (received in CWPA reply)
    * **Message Type:** `EAT!` (0x21746165)
    * **Payload:** A CMSampleBuffer containing:
        * `OutputPresentationTimestamp`: CMTime indicating the presentation time of the audio data.
        * `FormatDescription`: CMFormatDescription with audio format details (may be absent if already sent).
        * `SampleData`: Raw audio data, typically uncompressed PCM.

#### 4.4.7 NEED:

* **Purpose:** Requests the device to send more video data.
* **Packet Format:**
    * **Length:** 20 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID referencing the device's video clock (received in CVRP request).
    * **Message Type:** `NEED` (0x6E656564)

#### 4.4.8 HPD1/HPA1 (Hot Plug Detect):

* **Purpose:**  Sent by the host to specify the desired video (HPD1) and audio (HPA1) formats. 
* **Packet Format:**
    * **Length:** Variable
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 
        * HPD1: Empty CFTypeID (0x1)
        * HPA1: 8 byte CFTypeID referencing the device's audio clock (received in CWPA request)
    * **Message Type:** 
        * HPD1: `HPD1` (0x68706431)
        * HPA1: `HPA1` (0x68706131)
    * **Payload:**  A StringKeyDict containing device information and desired formats.

#### 4.4.9 HPD0/HPA0:

* **Purpose:**  Sent by the host to stop the device from streaming video (HPD0) and audio (HPA0) data.
* **Packet Format:**
    * **Length:** 20 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 
        * HPD0: Empty CFTypeID (0x1)
        * HPA0: 8 byte CFTypeID referencing the device's audio clock (received in CWPA request)
    * **Message Type:** 
        * HPD0: `HPD0` (0x68706430)
        * HPA0: `HPA0` (0x68706130)

#### 4.4.10 RELS (Release):

* **Purpose:** Signals the host that the device has released a specific clock.
* **Packet Format:**
    * **Length:** 20 bytes
    * **Magic Marker:** `ASYN` (0x6173796E)
    * **Clock Ref:** 8 byte CFTypeID of the released clock.
    * **Message Type:** `RELS` (0x72656C73)

This detailed description of message types provides a foundation for understanding the core communication elements of the iOS screen mirroring protocol. 
Further sections of the specification would elaborate on data structure formats, clock synchronization algorithms, and the session lifecycle.



```cpp
#include <cstdint>
#include <vector>
#include <string>
#include <memory>
#include <stdexcept>

// Common Utilities (You'll need to implement these)

namespace Utils {
  // Reads a uint32 from the buffer at the given offset in little-endian format.
  uint32_t readUint32LE(const std::vector<uint8_t>& buffer, size_t offset);

  // Writes a uint32 to the buffer at the given offset in little-endian format.
  void writeUint32LE(std::vector<uint8_t>& buffer, size_t offset, uint32_t value);

  // Reads a uint64 from the buffer at the given offset in little-endian format.
  uint64_t readUint64LE(const std::vector<uint8_t>& buffer, size_t offset);

  // Writes a uint64 to the buffer at the given offset in little-endian format.
  void writeUint64LE(std::vector<uint8_t>& buffer, size_t offset, uint64_t value);

  // Reads a string from the buffer at the given offset with the given length.
  std::string readString(const std::vector<uint8_t>& buffer, size_t offset, size_t length);

  // Writes a string to the buffer at the given offset.
  void writeString(std::vector<uint8_t>& buffer, size_t offset, const std::string& str);
}

// Base Packet Class

class Packet {
public:
  virtual ~Packet() = default;

  // Serializes the packet into a byte vector.
  virtual std::vector<uint8_t> serialize() const = 0;

  // Deserializes the packet from a byte vector.
  virtual void parse(const std::vector<uint8_t>& buffer) = 0;
};

// PING Packet

class PingPacket : public Packet {
public:
  static constexpr uint32_t Magic = 0x70696E67;  // "gnip"
  static constexpr uint32_t Length = 16;
  static constexpr uint64_t Header = 0x0000000100000000;

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> buffer(Length);
    Utils::writeUint32LE(buffer, 0, Length);
    Utils::writeUint32LE(buffer, 4, Magic);
    Utils::writeUint64LE(buffer, 8, Header);
    return buffer;
  }

  void parse(const std::vector<uint8_t>& buffer) override {
    if (buffer.size() != Length ||
        Utils::readUint32LE(buffer, 0) != Length ||
        Utils::readUint32LE(buffer, 4) != Magic ||
        Utils::readUint64LE(buffer, 8) != Header) {
      throw std::runtime_error("Invalid PING packet");
    }
  }
};

// CFTypeID (Clock Reference)

using CFTypeID = uint64_t;

// SYNC Packet Base Class

class SyncPacket : public Packet {
public:
  static constexpr uint32_t Magic = 0x73796E63;  // "cnys"

  SyncPacket(uint32_t messageType, CFTypeID clockRef = 1, uint64_t correlationId = 0) 
      : messageType(messageType), clockRef(clockRef), correlationId(correlationId) {}

  CFTypeID getClockRef() const { return clockRef; }
  uint64_t getCorrelationId() const { return correlationId; }

protected:
  uint32_t messageType;
  CFTypeID clockRef;
  uint64_t correlationId;
};

// CWPA Packet

class CwpaPacket : public SyncPacket {
public:
  static constexpr uint32_t MessageType = 0x63777061;  // "awpc"

  CwpaPacket(CFTypeID deviceClockRef, uint64_t correlationId = 0)
      : SyncPacket(MessageType, 1, correlationId), deviceClockRef(deviceClockRef) {}

  CFTypeID getDeviceClockRef() const { return deviceClockRef; }

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> buffer(36);
    Utils::writeUint32LE(buffer, 0, buffer.size());
    Utils::writeUint32LE(buffer, 4, Magic);
    Utils::writeUint64LE(buffer, 8, clockRef);
    Utils::writeUint32LE(buffer, 16, messageType);
    Utils::writeUint64LE(buffer, 20, correlationId);
    Utils::writeUint64LE(buffer, 28, deviceClockRef);
    return buffer;
  }

  void parse(const std::vector<uint8_t>& buffer) override {
    if (buffer.size() != 36 ||
        Utils::readUint32LE(buffer, 0) != 36 ||
        Utils::readUint32LE(buffer, 4) != Magic ||
        Utils::readUint32LE(buffer, 16) != messageType) {
      throw std::runtime_error("Invalid CWPA packet");
    }

    correlationId = Utils::readUint64LE(buffer, 20);
    deviceClockRef = Utils::readUint64LE(buffer, 28);
  }

private:
  CFTypeID deviceClockRef;
};

//  (More SYNC packet classes for AFMT, CVRP, CLOK, TIME, SKEW, OG, and STOP would follow here)

// ASYN Packet Base Class

class AsynPacket : public Packet {
public:
  static constexpr uint32_t Magic = 0x6173796E;  // "nysa"

  AsynPacket(uint32_t messageType, CFTypeID clockRef = 1) 
      : messageType(messageType), clockRef(clockRef) {}

  CFTypeID getClockRef() const { return clockRef; }

protected:
  uint32_t messageType;
  CFTypeID clockRef;
};

// SPRP Packet

class SprpPacket : public AsynPacket {
public:
  static constexpr uint32_t MessageType = 0x73707270;  // "prps"

  SprpPacket(const std::string& key, bool value, CFTypeID clockRef = 1) 
      : AsynPacket(MessageType, clockRef), key(key), value(value) {}

  std::string getKey() const { return key; }
  bool getValue() const { return value; }

  // ... (serialize and parse methods) ...
private:
  std::string key;
  bool value;
};

//  (More ASYN packet classes for SRAT, TBAS, TJMP, FEED, EAT!, NEED, HPD0/HPA0, and RELS would follow here)

// RPLY Packet

class ReplyPacket : public Packet {
public:
  static constexpr uint32_t Magic = 0x72706C79;  // "ylpr"

  ReplyPacket(uint64_t correlationId) : correlationId(correlationId) {}

  uint64_t getCorrelationId() const { return correlationId; }

  // ... (serialize and parse methods, specific to the reply type) ...

private:
  uint64_t correlationId;
};

int main() {
  // Example usage:
  PingPacket ping;
  auto pingBytes = ping.serialize();

  CwpaPacket cwpa(0x123456789ABCDEF0);
  auto cwpaBytes = cwpa.serialize(); 

  SprpPacket sprp("ObeyEmptyMediaMarkers", true);
  auto sprpBytes = sprp.serialize();

  // ... (Deserialize packets using the parse() method) ...

  return 0;
}
```

**Key Points and Notes:**

* **Common Utilities (`Utils` namespace):** This implementation relies on a set of utility functions for reading and writing data types from byte vectors. You'll need to implement these functions yourself.
* **Base Classes (`Packet`, `SyncPacket`, `AsynPacket`):** Base classes define common attributes and methods, promoting code reuse and maintainability.
* **Specific Packet Classes:**  Each packet type is represented by a dedicated class, encapsulating its specific structure and serialization/deserialization logic.
* **Exceptions:** The `parse()` methods should throw exceptions (`std::runtime_error`) if the packet format is invalid.
* **Missing Implementations:**  You'll need to complete the `serialize()` and `parse()` methods for all the remaining packet types, following the specifications outlined in Section 4 of the protocol document.
* **CMFormatDescription, CMSampleBuffer, AudioStreamBasicDescription:** These complex data structures require their own separate classes, potentially with nested structures to represent their content. 

**Example Usage:**

The `main()` function demonstrates how to create and serialize packet objects. You can similarly use the `parse()` method to deserialize packets from raw byte data. 

This C++ class structure provides a modular and extensible framework for representing and working with the iOS screen mirroring protocol messages. You can build upon this foundation to create a complete implementation of the protocol in C++. 
