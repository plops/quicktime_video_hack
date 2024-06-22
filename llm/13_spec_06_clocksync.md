## 6. Clock Synchronization

The iOS screen mirroring protocol relies on a sophisticated clock synchronization mechanism to ensure smooth and accurate playback of audio and video data. The host and the iOS device have independent clocks, which can drift over time, leading to synchronization issues. This section describes the protocol's approach to maintaining consistent timing between the two devices.

### 6.1 Clock References (CFTypeID)

Each clock involved in the communication is identified by a unique 64-bit value called a Clock Reference (CFTypeID). These references are exchanged in specific SYNC packets and serve as identifiers for subsequent messages related to those clocks.

### 6.2 Establishing Clock Synchronization

The initial synchronization of audio and video clocks happens through two dedicated SYNC packets:

* **SYNC_CWPA (Clock Walltime Anchor for Audio):**
    * The device initiates the audio clock synchronization by sending a `SYNC_CWPA` packet containing its audio clock reference.
    * The host responds by creating a local audio clock and sending its reference in a `RPLY` packet.
* **SYNC_CVRP (Clock and Video Rate Parameters):**
    * Similar to audio, the device sends a `SYNC_CVRP` packet with its video clock reference.
    * The host creates a local video clock and replies with its reference. 

At this point, both the host and device have references to each other's audio and video clocks, establishing a shared understanding of their respective timing systems.

### 6.3 Maintaining Synchronization

The protocol employs multiple strategies to maintain ongoing clock synchronization:

* **SYNC_TIME:**
    * The device periodically sends `SYNC_TIME` packets containing a clock reference.
    * The host replies with the current Core Media Time (CMTime) of the specified clock.
    * This exchange allows the device to track the host's clock progress and adjust its playback accordingly.
* **SYNC_SKEW:**
    * Focuses specifically on audio clock drift.
    * The device sends `SYNC_SKEW` packets with the audio clock reference.
    * The host calculates the skew (difference in frequency) between its local audio clock and the device's audio clock. This calculation utilizes timestamps from received `ASYN_EAT!` packets containing audio data.
    * The host responds with the calculated skew value.
    * The device uses this skew value to make tiny adjustments to its audio playback speed, preventing noticeable audio drift over time.
* **ASYN_NEED:**
    * While not directly involved in clock synchronization, `ASYN_NEED` packets contribute to maintaining smooth video playback.
    * The host regularly sends `ASYN_NEED` packets containing the device's video clock reference. This acts as a request for more video frames.
    * By aligning these requests with the device's video clock, the protocol ensures that the host receives video data at the appropriate rate, preventing buffering or stuttering issues.

### 6.4 Clock Creation

The `SYNC_CLOK` packet provides a mechanism for requesting the creation of new clocks on the host:

* The device sends `SYNC_CLOK` with a reference to the desired clock.
* The host creates the clock and responds with the new clock reference.
* This allows for the creation of clocks dedicated to specific purposes beyond audio and video, potentially for handling additional data streams or timing-related operations.

### 6.5 Summary

The clock synchronization mechanism in the iOS screen mirroring protocol is essential for achieving a seamless user experience. Through the exchange of clock references, time information, and skew calculations, the protocol ensures that the host and device maintain a consistent understanding of each other's timing systems. This allows for accurate and synchronized playback of audio and video data, despite the independent nature of their clocks. 
