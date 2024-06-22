## 3. Packet Structure

This section describes the general structure of data packets used in the iOS screen mirroring protocol. All communication between the host and the iOS device is carried out using these packets. 

### 3.1 Packet Types

The protocol utilizes four primary packet types:

* **PING:** Simple handshake packets used to establish and maintain the connection.
* **SYNC:** Synchronization packets used for clock synchronization and control flow. They require a corresponding RPLY packet as a response.
* **ASYN:** Asynchronous packets carrying informational data and commands that don't require a direct response. 
* **RPLY:** Reply packets sent in response to SYNC packets, carrying acknowledgements, data, or error codes.

### 3.2 Packet Header

Each packet, regardless of its type, starts with a common header structure:

| Field          | Size (bytes) | Description                                                                      |
|-----------------|---------------|----------------------------------------------------------------------------------|
| Length          | 4             | Total length of the packet, including the header and payload.                      |
| Magic Marker    | 4             | A 4-byte magic marker identifying the packet type (PING, SYNC, ASYN, RPLY).  |
| Clock Reference | 8             | A 64-bit identifier referencing the clock associated with this packet (optional).  |
| Correlation ID  | 8             | A 64-bit identifier used to correlate request and reply packets (optional).     |
| Message Type    | 4             | A 4-byte identifier specifying the sub-type of the packet (optional).             |

**Note:**

* The `Clock Reference`, `Correlation ID`, and `Message Type` fields are not present in all packets. Their presence depends on the specific packet type and its function.

### 3.3 Packet Payload

Following the header, each packet carries a payload containing data specific to the packet type and message. The payload format varies depending on the message and will be described in detail in the subsequent section on Message Types. 

**Example:**

A `SYNC_CWPA` packet requesting the host to create an audio clock would have the following structure:

| Field          | Value                                      |
|-----------------|-------------------------------------------|
| Length          | 36                                         |
| Magic Marker    | "SYNC" (0x73796E63)                       |
| Clock Reference | EmptyCFType (0x0000000000000001)           |
| Message Type    | "CWPA" (0x63777061)                       |
| Correlation ID  | A unique 64-bit identifier              |
| Payload         | 8 bytes - Device's audio clock CFTypeID |

This packet tells the host to create a local audio clock and then reply with a `RPLY` packet containing the host's newly generated clock reference. 

This section provided a general overview of the packet structure used in the iOS screen mirroring protocol.  The next section will delve deeper into the specific message types and their payload formats. 


```cpp
#include <cstdint>
#include <vector>
#include <string>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <iomanip>

namespace ios_screen_mirroring {

// Utility function to print hex dumps for debugging
void printHexDump(const std::vector<uint8_t>& data) {
  for (size_t i = 0; i < data.size(); ++i) {
    std::cout << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(data[i]) << " ";
    if ((i + 1) % 16 == 0) {
      std::cout << std::endl;
    }
  }
  std::cout << std::endl;
}

// Base packet class
class Packet {
public:
  enum Type { PING, SYNC, ASYN, RPLY };

  Packet(Type type) : type_(type) {}
  virtual ~Packet() {}

  Type getType() const { return type_; }

  virtual std::vector<uint8_t> serialize() const = 0;
  virtual void parse(const std::vector<uint8_t>& data) = 0;

protected:
  Type type_;
  uint32_t length_;
  uint64_t clockRef_;
  uint64_t correlationID_;

  void parseHeader(const std::vector<uint8_t>& data) {
    if (data.size() < 12) {
      throw std::runtime_error("Invalid packet header: Insufficient data");
    }

    length_ = *reinterpret_cast<const uint32_t*>(data.data());
    clockRef_ = *reinterpret_cast<const uint64_t*>(data.data() + 4);
  }

  std::vector<uint8_t> serializeHeader() const {
    std::vector<uint8_t> header(12);
    *reinterpret_cast<uint32_t*>(header.data()) = length_;
    *reinterpret_cast<uint64_t*>(header.data() + 4) = clockRef_;
    return header;
  }
};

// Ping packet
class PingPacket : public Packet {
public:
  PingPacket() : Packet(PING) {
    length_ = 16;
  }

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> data(length_);
    *reinterpret_cast<uint32_t*>(data.data()) = length_;
    *reinterpret_cast<uint32_t*>(data.data() + 4) = 0x70696E67; // "PING"
    *reinterpret_cast<uint64_t*>(data.data() + 8) = 0x0000000100000000;
    return data;
  }

  void parse(const std::vector<uint8_t>& data) override {
    if (data.size() != 16 || 
        *reinterpret_cast<const uint32_t*>(data.data() + 4) != 0x70696E67 ||
        *reinterpret_cast<const uint64_t*>(data.data() + 8) != 0x0000000100000000) {
      throw std::runtime_error("Invalid PING packet");
    }
  }
};

// SYNC packet base class
class SyncPacket : public Packet {
public:
  SyncPacket(uint32_t messageType) : Packet(SYNC), messageType_(messageType) {
    length_ = 28; // Base length for SYNC packets
  }

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> data = serializeHeader();
    data.resize(length_);
    *reinterpret_cast<uint32_t*>(data.data() + 12) = messageType_;
    *reinterpret_cast<uint64_t*>(data.data() + 16) = correlationID_;
    return data;
  }

  void parse(const std::vector<uint8_t>& data) override {
    parseHeader(data);
    if (data.size() < 24) {
      throw std::runtime_error("Invalid SYNC packet header: Insufficient data");
    }
    messageType_ = *reinterpret_cast<const uint32_t*>(data.data() + 12);
    correlationID_ = *reinterpret_cast<const uint64_t*>(data.data() + 16);
  }

  uint32_t getMessageType() const { return messageType_; }
  uint64_t getCorrelationID() const { return correlationID_; }

protected:
  uint32_t messageType_;
};

// RPLY packet
class ReplyPacket : public Packet {
public:
  ReplyPacket() : Packet(RPLY) {}

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> data = serializeHeader();
    data.resize(length_);
    *reinterpret_cast<uint64_t*>(data.data() + 12) = correlationID_;
    // Add additional payload data based on the corresponding SYNC packet 
    return data;
  }

  void parse(const std::vector<uint8_t>& data) override {
    parseHeader(data);
    if (data.size() < 20) {
      throw std::runtime_error("Invalid RPLY packet header: Insufficient data");
    }
    correlationID_ = *reinterpret_cast<const uint64_t*>(data.data() + 12);
  }

  uint64_t getCorrelationID() const { return correlationID_; }
};

// ASYN packet base class
class AsynPacket : public Packet {
public:
  AsynPacket(uint32_t messageType) : Packet(ASYN), messageType_(messageType) {}

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> data = serializeHeader();
    data.resize(length_);
    *reinterpret_cast<uint32_t*>(data.data() + 12) = messageType_;
    // Add additional payload data based on the specific ASYN packet type
    return data;
  }

  void parse(const std::vector<uint8_t>& data) override {
    parseHeader(data);
    if (data.size() < 16) {
      throw std::runtime_error("Invalid ASYN packet header: Insufficient data");
    }
    messageType_ = *reinterpret_cast<const uint32_t*>(data.data() + 12);
  }

  uint32_t getMessageType() const { return messageType_; }
};

// Example: CWPA Packet
class CwpaPacket : public SyncPacket {
public:
  CwpaPacket() : SyncPacket(0x63777061 /* "CWPA" */) {}

  std::vector<uint8_t> serialize() const override {
    std::vector<uint8_t> data = SyncPacket::serialize();
    data.resize(length_);
    *reinterpret_cast<uint64_t*>(data.data() + 24) = deviceClockRef_;
    return data;
  }

  void parse(const std::vector<uint8_t>& data) override {
    SyncPacket::parse(data);
    if (data.size() < 32) {
      throw std::runtime_error("Invalid CWPA packet: Insufficient data");
    }
    deviceClockRef_ = *reinterpret_cast<const uint64_t*>(data.data() + 24);
  }

  uint64_t getDeviceClockRef() const { return deviceClockRef_; }

private:
  uint64_t deviceClockRef_;
};

} // namespace ios_screen_mirroring

int main() {
  // Example usage:
  ios_screen_mirroring::CwpaPacket cwpaPacket;
  cwpaPacket.parse({0x24, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                    0x63, 0x77, 0x70, 0x61, 0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF,
                    0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10});
  std::cout << "CWPA Correlation ID: 0x" << std::hex << cwpaPacket.getCorrelationID() << std::endl;
  std::cout << "CWPA Device Clock Ref: 0x" << std::hex << cwpaPacket.getDeviceClockRef() << std::endl;

  ios_screen_mirroring::PingPacket pingPacket;
  auto pingData = pingPacket.serialize();
  std::cout << "Ping Packet: " << std::endl;
  printHexDump(pingData);

  return 0;
}
```

**Explanation:**

1. **Namespace:** All classes are defined within the `ios_screen_mirroring` namespace.
2. **Packet base class:**
   - Contains common fields: `type_`, `length_`, `clockRef_`, `correlationID_`.
   - Defines virtual `serialize()` and `parse()` methods for polymorphism.
   - Protected helper methods `parseHeader()` and `serializeHeader()` to handle common header logic.
3. **Specific Packet Classes:**
   - `PingPacket`: Represents a ping packet with fixed length and magic.
   - `SyncPacket`: Base class for all SYNC packets.
   - `ReplyPacket`: Base class for all RPLY packets.
   - `AsynPacket`: Base class for all ASYN packets.
   - `CwpaPacket`: Example implementation of a specific SYNC packet (`CWPA`).
4. **Serialization and Parsing:**
   - Each packet class overrides the `serialize()` and `parse()` methods.
   - `serialize()`: Returns a `std::vector<uint8_t>` representing the serialized packet.
   - `parse()`: Takes a `std::vector<uint8_t>` as input and parses the packet data.
5. **Error Handling:**
   - The `parse()` methods throw `std::runtime_error` if invalid packet data is encountered.
6. **Main Function:**
   - Demonstrates basic usage by creating a `CwpaPacket` object, parsing sample data, and printing extracted values.
   - Shows serialization of a `PingPacket` and prints the hex dump.

**To implement additional packet types:**

1. Create a new class inheriting from `SyncPacket`, `ReplyPacket`, or `AsynPacket`.
2. Override `serialize()` to add specific payload data.
3. Override `parse()` to extract specific payload data and handle validation.

This structure provides a clean and extensible way to represent the iOS screen mirroring protocol packets in C++. 
Remember to implement the remaining packet types based on the protocol specification and your specific needs.
