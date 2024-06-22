## 5. Data Structures

This section describes the various data structures used in the iOS screen mirroring protocol, their formats, and how to serialize and deserialize them. Understanding these structures is crucial for correctly interpreting and generating protocol messages.

### 5.1 Dictionaries

Dictionaries are key-value pairs used extensively in the protocol to carry various information, such as device capabilities, stream properties, and format descriptions. The protocol employs two types of dictionaries:

**5.1.1 StringKeyDict:**

* **Structure:** A `StringKeyDict` consists of an array of `StringKeyEntry` structs. 
* **StringKeyEntry:** Each `StringKeyEntry` contains:
    * `Key`: A string representing the key.
    * `Value`: An arbitrary value, which can be another dictionary, a number, a boolean, a byte array, or a `FormatDescriptor`.
* **Serialization:**
    * Dictionaries begin with a 4-byte length field followed by the "dict" magic marker (0x74636964).
    * Each `StringKeyEntry` is serialized as follows:
        * 4-byte length field.
        * "keyv" magic marker (0x7679656B).
        * Key length (4 bytes).
        * "strk" magic marker (0x6B727473).
        * Key string.
        * Value length (4 bytes).
        * Value type magic marker (see table below).
        * Value data.
* **Deserialization:** Follows the serialization format in reverse.

**5.1.2 IndexKeyDict:**

* **Structure:** Similar to `StringKeyDict`, but uses `IndexKeyEntry` structs.
* **IndexKeyEntry:** Each `IndexKeyEntry` contains:
    * `Key`: A 2-byte unsigned integer representing the key.
    * `Value`: Similar to `StringKeyEntry`, can hold various data types.
* **Serialization:**
    * Similar to `StringKeyDict`, but uses the "idxk" magic marker (0x6964786B) for the key.
* **Deserialization:** Follows the serialization format in reverse.

**Value Type Magic Markers:**

| Magic Marker (Little Endian) | Data Type | Description |
|---|---|---|
| vlub (bulv) | Boolean | True (0x01) or False (0x00) |
| vrts (strv) | String | ASCII encoded string |
| vtad (datv) | Byte Array | Raw byte data |
| vbmn (nmbv) | NSNumber |  NSNumber structure |
| tcid (dict) | Dictionary | StringKeyDict or IndexKeyDict |
| csdf (fdsc) | CMFormatDescription | FormatDescriptor structure |

### 5.2 CMTime

`CMTime` represents a timestamp and is based on the `CMTime` struct defined in the Core Media framework on macOS and iOS.

* **Structure:**
    * `CMTimeValue`: A 64-bit unsigned integer representing the time value.
    * `CMTimeScale`: A 32-bit unsigned integer representing the time scale (units per second).
    * `CMTimeFlags`: A 32-bit unsigned integer containing flags, e.g., `KCMTimeFlagsHasBeenRounded`, `KCMTimeFlagsValid`.
    * `CMTimeEpoch`: A 64-bit unsigned integer differentiating between equal timestamps from different loops or sequences. 
* **Serialization:** The fields are serialized in the order listed above, using little-endian byte order.
* **Deserialization:** Follows the serialization format in reverse.

### 5.3 CMSampleBuffer

`CMSampleBuffer` holds actual audio or video data and associated metadata, such as timestamps and format descriptions. 

* **Structure:**
    * `OutputPresentationTimestamp`: A `CMTime` indicating the presentation time of the sample.
    * `FormatDescription`: A `FormatDescriptor` containing codec and format information (optional).
    * `HasFormatDescription`: A boolean indicating the presence of a format description.
    * `NumSamples`: Number of samples in the buffer.
    * `SampleTimingInfoArray`: An array of `CMSampleTimingInfo` structs providing timing details for each sample.
    * `SampleData`: Raw audio or video data.
    * `SampleSizes`: An array of integers specifying the size of each sample in bytes.
    * `Attachments`: An `IndexKeyDict` containing additional attachments.
    * `Sary`: An `IndexKeyDict` with a boolean value (purpose unclear).

* **Serialization:**
    * Begins with a 4-byte length field followed by the "sbuf" magic marker (0x73627566).
    * Individual data elements within the buffer are identified by specific magic markers (e.g., "opts" for `OutputPresentationTimestamp`, "sdat" for `SampleData`).
    * Each data element is serialized according to its respective format.
* **Deserialization:** Follows the serialization format in reverse, parsing individual elements based on their magic markers.

### 5.4 NSNumber

`NSNumber` represents a numerical value and can hold various numerical data types.

* **Structure:**
    * `typeSpecifier`: A single byte indicating the data type:
        * 0x03: 32-bit integer (`IntValue`)
        * 0x04: 64-bit integer (`LongValue`)
        * 0x06: 64-bit float (`FloatValue`)
    * `IntValue`: A 32-bit integer (used if `typeSpecifier` is 0x03).
    * `LongValue`: A 64-bit integer (used if `typeSpecifier` is 0x04).
    * `FloatValue`: A 64-bit float (used if `typeSpecifier` is 0x06).

* **Serialization:**
    * The `typeSpecifier` byte is serialized first.
    * Depending on the `typeSpecifier`, the corresponding value field is serialized using little-endian byte order.
* **Deserialization:** Follows the serialization format in reverse, interpreting the value based on the `typeSpecifier`.

### 5.5 CMFormatDescription

`CMFormatDescription` (represented as `FormatDescriptor` in this protocol) encapsulates information about the media format, such as codec, dimensions, and extensions.

* **Structure:**
    * `MediaType`: A 32-bit unsigned integer indicating the media type (e.g., `MediaTypeVideo`, `MediaTypeSound`).
    * `VideoDimensionWidth`: Width of the video frame in pixels (used if `MediaType` is `MediaTypeVideo`).
    * `VideoDimensionHeight`: Height of the video frame in pixels (used if `MediaType` is `MediaTypeVideo`).
    * `Codec`: A 32-bit unsigned integer identifying the codec (e.g., `CodecAvc1` for H.264).
    * `Extensions`: An `IndexKeyDict` containing additional codec-specific parameters.
    * `PPS`: Raw bytes of the Picture Parameter Set (PPS) for H.264 video.
    * `SPS`: Raw bytes of the Sequence Parameter Set (SPS) for H.264 video.
    * `AudioStreamBasicDescription`: An `AudioStreamBasicDescription` struct containing audio format details (used if `MediaType` is `MediaTypeSound`).
* **Serialization:**
    * Begins with a 4-byte length field followed by the "fdsc" magic marker (0x66647363).
    * Fields are serialized in a specific order using dedicated magic markers and length fields.
    * The `Extensions` field, if present, is serialized as an `IndexKeyDict`.
* **Deserialization:** Follows the serialization format in reverse, interpreting fields based on their magic markers and length fields. 

This detailed explanation of the core data structures should enable developers to understand the internals of the iOS screen mirroring protocol and implement compatible applications or tools. 


```cpp
#include <cstdint>
#include <vector>
#include <string>
#include <variant>
#include <iostream>

// Define constants for magic markers and data types
namespace CoreMedia {
    enum class MagicMarker : uint32_t {
        KeyValuePair = 0x7679656B,  // keyv
        StringKey = 0x6B727473,    // strk
        IntKey = 0x6B786469,        // idxk
        BooleanValue = 0x766C7562, // bulv
        Dictionary = 0x74636964,    // dict
        DataValue = 0x76746164,     // datv
        StringValue = 0x76727473,  // strv
        FormatDescriptor = 0x63736466, // fdsc
        MediaType = 0x6169646D,    // mdia
        VideoDimension = 0x6D696476, // vdim
        Codec = 0x63646F63,        // codc
        Extension = 0x6E747865,      // extn
        AudioStreamBasicDescription = 0x64627361, // asdb
    };

    enum class MediaType : uint32_t {
        Video = 0x65646976, // vide
        Sound = 0x6E756F73  // soun
    };

    enum class Codec : uint32_t {
        Avc1 = 0x31637661 // avc1
    };
}

// Helper functions for serialization and deserialization
namespace Utils {
    template<typename T>
    void SerializeValue(std::vector<uint8_t>& buffer, const T& value) {
        const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&value);
        buffer.insert(buffer.end(), bytes, bytes + sizeof(T));
    }

    template<typename T>
    T DeserializeValue(const std::vector<uint8_t>& buffer, size_t& offset) {
        T value;
        std::memcpy(&value, buffer.data() + offset, sizeof(T));
        offset += sizeof(T);
        return value;
    }
}

// Class representing a CoreMedia dictionary
class Dictionary {
public:
    using ValueType = std::variant<bool, uint32_t, uint64_t, double, std::string, std::vector<uint8_t>, Dictionary, FormatDescriptor>;
    using Entry = std::pair<std::string, ValueType>;

    std::vector<Entry> entries;

    std::vector<uint8_t> Serialize() const {
        std::vector<uint8_t> buffer;
        // Serialize entries
        for (const auto& entry : entries) {
            // Serialize key-value pair
            std::vector<uint8_t> keyValuePairBuffer;
            Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(entry.first.size() + 8));
            Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::StringKey);
            keyValuePairBuffer.insert(keyValuePairBuffer.end(), entry.first.begin(), entry.first.end());

            std::visit([&keyValuePairBuffer](const auto& value) {
                using T = std::decay_t<decltype(value)>;
                if constexpr (std::is_same_v<T, bool>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(9));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::BooleanValue);
                    Utils::SerializeValue(keyValuePairBuffer, value ? 1 : 0);
                } else if constexpr (std::is_same_v<T, uint32_t>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(12));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::NumberValue);
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint8_t>(3));
                    Utils::SerializeValue(keyValuePairBuffer, value);
                } else if constexpr (std::is_same_v<T, uint64_t>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(16));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::NumberValue);
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint8_t>(4));
                    Utils::SerializeValue(keyValuePairBuffer, value);
                } else if constexpr (std::is_same_v<T, double>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(16));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::NumberValue);
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint8_t>(6));
                    Utils::SerializeValue(keyValuePairBuffer, value);
                } else if constexpr (std::is_same_v<T, std::string>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(value.size() + 8));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::StringValue);
                    keyValuePairBuffer.insert(keyValuePairBuffer.end(), value.begin(), value.end());
                } else if constexpr (std::is_same_v<T, std::vector<uint8_t>>) {
                    Utils::SerializeValue(keyValuePairBuffer, static_cast<uint32_t>(value.size() + 8));
                    Utils::SerializeValue(keyValuePairBuffer, CoreMedia::MagicMarker::DataValue);
                    keyValuePairBuffer.insert(keyValuePairBuffer.end(), value.begin(), value.end());
                } else if constexpr (std::is_same_v<T, Dictionary>) {
                    auto dictBuffer = value.Serialize();
                    keyValuePairBuffer.insert(keyValuePairBuffer.end(), dictBuffer.begin(), dictBuffer.end());
                } else if constexpr (std::is_same_v<T, FormatDescriptor>) {
                    auto fdscBuffer = value.Serialize();
                    keyValuePairBuffer.insert(keyValuePairBuffer.end(), fdscBuffer.begin(), fdscBuffer.end());
                }
            }, entry.second);

            Utils::SerializeValue(buffer, static_cast<uint32_t>(keyValuePairBuffer.size() + 8));
            Utils::SerializeValue(buffer, CoreMedia::MagicMarker::KeyValuePair);
            buffer.insert(buffer.end(), keyValuePairBuffer.begin(), keyValuePairBuffer.end());
        }

        // Serialize dictionary header
        Utils::SerializeValue(buffer, static_cast<uint32_t>(buffer.size() + 8));
        Utils::SerializeValue(buffer, CoreMedia::MagicMarker::Dictionary);
        return buffer;
    }

    static Dictionary Parse(const std::vector<uint8_t>& buffer, size_t& offset) {
        Dictionary dict;
        uint32_t length = Utils::DeserializeValue<uint32_t>(buffer, offset);
        CoreMedia::MagicMarker magic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);
        if (magic != CoreMedia::MagicMarker::Dictionary) {
            throw std::runtime_error("Invalid dictionary magic marker");
        }

        size_t endOffset = offset + length - 8;
        while (offset < endOffset) {
            uint32_t keyValuePairLength = Utils::DeserializeValue<uint32_t>(buffer, offset);
            CoreMedia::MagicMarker keyValuePairMagic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);
            if (keyValuePairMagic != CoreMedia::MagicMarker::KeyValuePair) {
                throw std::runtime_error("Invalid key-value pair magic marker");
            }

            // Parse key
            uint32_t keyLength = Utils::DeserializeValue<uint32_t>(buffer, offset);
            CoreMedia::MagicMarker keyMagic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);
            if (keyMagic != CoreMedia::MagicMarker::StringKey) {
                throw std::runtime_error("Invalid string key magic marker");
            }
            std::string key(buffer.begin() + offset, buffer.begin() + offset + keyLength - 8);
            offset += keyLength - 8;

            // Parse value
            dict.entries.emplace_back(key, ParseValue(buffer, offset));
        }

        return dict;
    }

private:
    static ValueType ParseValue(const std::vector<uint8_t>& buffer, size_t& offset) {
        uint32_t valueLength = Utils::DeserializeValue<uint32_t>(buffer, offset);
        CoreMedia::MagicMarker valueMagic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);

        switch (valueMagic) {
            case CoreMedia::MagicMarker::BooleanValue:
                return Utils::DeserializeValue<bool>(buffer, offset);
            case CoreMedia::MagicMarker::StringValue: {
                std::string value(buffer.begin() + offset, buffer.begin() + offset + valueLength - 8);
                offset += valueLength - 8;
                return value;
            }
            case CoreMedia::MagicMarker::DataValue: {
                std::vector<uint8_t> value(buffer.begin() + offset, buffer.begin() + offset + valueLength - 8);
                offset += valueLength - 8;
                return value;
            }
            case CoreMedia::MagicMarker::NumberValue: {
                uint8_t typeSpecifier = Utils::DeserializeValue<uint8_t>(buffer, offset);
                switch (typeSpecifier) {
                    case 3:
                        return Utils::DeserializeValue<uint32_t>(buffer, offset);
                    case 4:
                        return Utils::DeserializeValue<uint64_t>(buffer, offset);
                    case 6:
                        return Utils::DeserializeValue<double>(buffer, offset);
                    default:
                        throw std::runtime_error("Unknown NSNumber type specifier");
                }
            }
            case CoreMedia::MagicMarker::Dictionary:
                return Parse(buffer, offset);
            case CoreMedia::MagicMarker::FormatDescriptor:
                return FormatDescriptor::Parse(buffer, offset);
            default:
                throw std::runtime_error("Unknown value magic marker");
        }
    }
};

// Class representing a CoreMedia CMTime structure
class CMTime {
public:
    uint64_t value;
    uint32_t timescale;
    uint32_t flags;
    uint64_t epoch;

    std::vector<uint8_t> Serialize() const {
        std::vector<uint8_t> buffer;
        Utils::SerializeValue(buffer, value);
        Utils::SerializeValue(buffer, timescale);
        Utils::SerializeValue(buffer, flags);
        Utils::SerializeValue(buffer, epoch);
        return buffer;
    }

    static CMTime Parse(const std::vector<uint8_t>& buffer, size_t& offset) {
        CMTime time;
        time.value = Utils::DeserializeValue<uint64_t>(buffer, offset);
        time.timescale = Utils::DeserializeValue<uint32_t>(buffer, offset);
        time.flags = Utils::DeserializeValue<uint32_t>(buffer, offset);
        time.epoch = Utils::DeserializeValue<uint64_t>(buffer, offset);
        return time;
    }
};

// Class representing a CoreMedia CMSampleBuffer structure
class CMSampleBuffer {
public:
    CMTime outputPresentationTimestamp;
    std::optional<FormatDescriptor> formatDescription;
    uint32_t numSamples;
    std::vector<uint8_t> sampleData;
    std::vector<uint32_t> sampleSizes;
    Dictionary attachments;
    Dictionary sary;
};

// Class representing a CoreMedia CMFormatDescription structure
class FormatDescriptor {
public:
    CoreMedia::MediaType mediaType;
    uint32_t videoDimensionWidth;
    uint32_t videoDimensionHeight;
    CoreMedia::Codec codec;
    Dictionary extensions;
    std::vector<uint8_t> PPS;
    std::vector<uint8_t> SPS;
    AudioStreamBasicDescription audioStreamBasicDescription;

    std::vector<uint8_t> Serialize() const {
        std::vector<uint8_t> buffer;
        // Serialize media type
        Utils::SerializeValue(buffer, static_cast<uint32_t>(12));
        Utils::SerializeValue(buffer, CoreMedia::MagicMarker::MediaType);
        Utils::SerializeValue(buffer, mediaType);

        if (mediaType == CoreMedia::MediaType::Video) {
            // Serialize video dimension
            Utils::SerializeValue(buffer, static_cast<uint32_t>(16));
            Utils::SerializeValue(buffer, CoreMedia::MagicMarker::VideoDimension);
            Utils::SerializeValue(buffer, videoDimensionWidth);
            Utils::SerializeValue(buffer, videoDimensionHeight);

            // Serialize codec
            Utils::SerializeValue(buffer, static_cast<uint32_t>(12));
            Utils::SerializeValue(buffer, CoreMedia::MagicMarker::Codec);
            Utils::SerializeValue(buffer, codec);

            // Serialize extensions
            auto extBuffer = extensions.Serialize();
            buffer.insert(buffer.end(), extBuffer.begin(), extBuffer.end());
        } else if (mediaType == CoreMedia::MediaType::Sound) {
            // Serialize audio stream basic description
            auto asbdBuffer = audioStreamBasicDescription.Serialize();
            buffer.insert(buffer.end(), asbdBuffer.begin(), asbdBuffer.end());
        }

        // Serialize format descriptor header
        Utils::SerializeValue(buffer, static_cast<uint32_t>(buffer.size() + 8));
        Utils::SerializeValue(buffer, CoreMedia::MagicMarker::FormatDescriptor);
        return buffer;
    }

    static FormatDescriptor Parse(const std::vector<uint8_t>& buffer, size_t& offset) {
        FormatDescriptor fdsc;
        uint32_t length = Utils::DeserializeValue<uint32_t>(buffer, offset);
        CoreMedia::MagicMarker magic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);
        if (magic != CoreMedia::MagicMarker::FormatDescriptor) {
            throw std::runtime_error("Invalid format descriptor magic marker");
        }

        size_t endOffset = offset + length - 8;
        while (offset < endOffset) {
            uint32_t elementLength = Utils::DeserializeValue<uint32_t>(buffer, offset);
            CoreMedia::MagicMarker elementMagic = Utils::DeserializeValue<CoreMedia::MagicMarker>(buffer, offset);

            switch (elementMagic) {
                case CoreMedia::MagicMarker::MediaType:
                    fdsc.mediaType = Utils::DeserializeValue<CoreMedia::MediaType>(buffer, offset);
                    break;
                case CoreMedia::MagicMarker::VideoDimension:
                    fdsc.videoDimensionWidth = Utils::DeserializeValue<uint32_t>(buffer, offset);
                    fdsc.videoDimensionHeight = Utils::DeserializeValue<uint32_t>(buffer, offset);
                    break;
                case CoreMedia::MagicMarker::Codec:
                    fdsc.codec = Utils::DeserializeValue<CoreMedia::Codec>(buffer, offset);
                    break;
                case CoreMedia::MagicMarker::Extension:
                    fdsc.extensions = Dictionary::Parse(buffer, offset);
                    break;
                case CoreMedia::MagicMarker::AudioStreamBasicDescription:
                    fdsc.audioStreamBasicDescription = AudioStreamBasicDescription::Parse(buffer, offset);
                    break;
                default:
                    throw std::runtime_error("Unknown format descriptor element magic marker");
            }
        }

        // Extract PPS and SPS from extensions
        if (fdsc.mediaType == CoreMedia::MediaType::Video) {
            auto ppsSpsEntry = fdsc.extensions.entries[0];
            if (ppsSpsEntry.first == "PPSAndSPS") {
                auto& ppsSpsData = std::get<std::vector<uint8_t>>(ppsSpsEntry.second);
                size_t ppsSpsOffset = 0;
                fdsc.PPS = DeserializeData(ppsSpsData, ppsSpsOffset);
                fdsc.SPS = DeserializeData(ppsSpsData, ppsSpsOffset);
            }
        }

        return fdsc;
    }

private:
    static std::vector<uint8_t> DeserializeData(const std::vector<uint8_t>& buffer, size_t& offset) {
        uint32_t dataLength = Utils::DeserializeValue<uint32_t>(buffer, offset);
        std::vector<uint8_t> data(buffer.begin() + offset, buffer.begin() + offset + dataLength);
        offset += dataLength;
        return data;
    }
};

// Class representing a CoreMedia AudioStreamBasicDescription structure
class AudioStreamBasicDescription {
public:
    double mSampleRate;
    uint32_t mFormatID;
    uint32_t mFormatFlags;
    uint32_t mBytesPerPacket;
    uint32_t mFramesPerPacket;
    uint32_t mBytesPerFrame;
    uint32_t mChannelsPerFrame;
    uint32_t mBitsPerChannel;
    uint32_t mReserved;

    std::vector<uint8_t> Serialize() const {
        std::vector<uint8_t> buffer;
        Utils::SerializeValue(buffer, mSampleRate);
        Utils::SerializeValue(buffer, mFormatID);
        Utils::SerializeValue(buffer, mFormatFlags);
        Utils::SerializeValue(buffer, mBytesPerPacket);
        Utils::SerializeValue(buffer, mFramesPerPacket);
        Utils::SerializeValue(buffer, mBytesPerFrame);
        Utils::SerializeValue(buffer, mChannelsPerFrame);
        Utils::SerializeValue(buffer, mBitsPerChannel);
        Utils::SerializeValue(buffer, mReserved);
        return buffer;
    }

    static AudioStreamBasicDescription Parse(const std::vector<uint8_t>& buffer, size_t& offset) {
        AudioStreamBasicDescription asbd;
        asbd.mSampleRate = Utils::DeserializeValue<double>(buffer, offset);
        asbd.mFormatID = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mFormatFlags = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mBytesPerPacket = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mFramesPerPacket = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mBytesPerFrame = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mChannelsPerFrame = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mBitsPerChannel = Utils::DeserializeValue<uint32_t>(buffer, offset);
        asbd.mReserved = Utils::DeserializeValue<uint32_t>(buffer, offset);
        return asbd;
    }
};

// Example usage
int main() {
    // Create a dictionary
    Dictionary dict;
    dict.entries.emplace_back("Key1", true);
    dict.entries.emplace_back("Key2", static_cast<uint32_t>(12345));
    dict.entries.emplace_back("Key3", std::string("Hello, world!"));

    // Serialize the dictionary
    auto serializedDict = dict.Serialize();

    // Print the serialized data
    std::cout << "Serialized dictionary:" << std::endl;
    for (auto byte : serializedDict) {
        std::cout << std::hex << static_cast<int>(byte) << " ";
    }
    std::cout << std::dec << std::endl;

    // Deserialize the dictionary
    size_t offset = 0;
    auto deserializedDict = Dictionary::Parse(serializedDict, offset);

    // Print the deserialized data
    std::cout << "Deserialized dictionary:" << std::endl;
    for (const auto& entry : deserializedDict.entries) {
        std::cout << entry.first << ": ";
        std::visit([](const auto& value) { std::cout << value; }, entry.second);
        std::cout << std::endl;
    }

    return 0;
}
```

This code defines the following classes:

* **`Dictionary`:** Represents a CoreMedia dictionary with string keys and variant values.
* **`CMTime`:** Represents a CoreMedia `CMTime` structure for timestamps.
* **`CMSampleBuffer`:** Represents a CoreMedia `CMSampleBuffer` structure, although not fully implemented for brevity.
* **`FormatDescriptor`:** Represents a CoreMedia `CMFormatDescription` structure for media format information.
* **`AudioStreamBasicDescription`:** Represents a CoreMedia `AudioStreamBasicDescription` structure for audio format details.

Each class has `Serialize` and `Parse` methods for converting between the object representation and its serialized byte array form. The code also includes helper functions for serializing and deserializing basic data types and a simple example demonstrating the usage of the `Dictionary` class.

This is a basic implementation and can be further extended to fully support the complexities of the iOS screen mirroring protocol. Features like handling nested dictionaries, parsing `CMSampleBuffer` data, and extracting PPS and SPS from `FormatDescriptor` need to be implemented based on the specific requirements of your application.
