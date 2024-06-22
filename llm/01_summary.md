i used gemini 1.5 pro on 2024-06-22 using the context produced by gather01_files.sh.
the context is around 100k tokens.

## iOS ScreenSharing Feature Technical Documentation Summary:

**Enabling ScreenSharing on USB Level:**

* iOS devices have hidden configurations accessible via LibUsb.
* The default configuration is for USBMux with subclass `0xFE`.
* The hidden QuickTime configuration (QT-Config) has subclass `0x2A`.
* To enable QT-Config, send a specific control request to the device.
* The new configuration enables AV streaming with 4 bulk endpoints.

**AV Session Lifecycle:**

* **Initiate:**
    * Enable QT-Config, claim endpoint, exchange PING packets.
    * Receive SYNC CWPA, create local clock, reply with clockRef.
    * Send ASYN_HPD1, ASYN_HPA1 with device audio clockRef.
    * Exchange SYNC AFMT, SYNC CVRP with clockRefs.
    * Send ASYN NEED with device video clockRef.
    * Receive ASYN Set Properties, SYNC CLOK, SYNC TIME packets.
* **Receive Data:**
    * Receive FEED (video) and EAT! (audio) packets.
    * Periodically send NEED packets for video.
* **Shut Down:**
    * Send ASYN HPA0, ASYN HPD0 to stop streaming.
    * Receive SYNC STOP, reply with zeros.
    * Receive ASYN RELS for local clockRefs.
    * Release endpoint and set device back to USBMux config.

**Protocol Reference:**

* **PING:** Simple handshake packet.
* **SYNC:** Clock synchronization packets requiring RPLY:
    * **CWPA:** Initiate audio stream, exchange clockRefs.
    * **AFMT:** Audio format information (AudioStreamBasicDescription).
    * **CVRP:** Create video clock, exchange clockRefs.
    * **CLOK:** Create a new clock, exchange clockRefs.
    * **TIME:** Request/reply with current CMTime for a clockRef.
    * **SKEW:** Inform device about audio clock skew.
    * **OG:** Unknown purpose, exchange data.
    * **STOP:** Signal to stop clock.
* **ASYN:** Informational packets, no reply needed:
    * **SPRP:** Set video stream properties.
    * **SRAT:** Set time rate and anchor, possibly related to AVPlayer rate.
    * **TBAS:** Inform about a new TimeBase, contains clockRefs.
    * **TJMP:** Notify about a TimeBase time jump.
    * **FEED:** Video data (CMSampleBuffer with h264).
    * **EAT!:** Audio data (CMSampleBuffer).
    * **NEED:** Request more video data.
    * **HPD0/HPA0:** Stop video/audio streaming.
    * **RELS:** Signal a released clock.

**Serializing/Deserializing:**

* **Dictionaries:** Two types: string keys or 4-byte integer index keys.
* **CMTime:** Follows CMTime.h struct.
* **CMSampleBuffer:** Contains AV data and metadata.
* **NSNumber:** Simple representation, can be int32, int64, or float64.
* **CMFormatDescription:** Similar to CMFormatDescription.h.

**Clocks and CMSync:**

* Packet references likely refer to CMClocks.
* Use monotonic clocks for CMTime calculations.
* Skew calculation involves comparing time differences between clocks.
