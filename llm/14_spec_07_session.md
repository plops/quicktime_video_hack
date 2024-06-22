## 7. Session Lifecycle

This section describes the step-by-step process of an iOS screen mirroring session, from initiation to data streaming and finally shutdown.

**7.1 Initiation Phase:**

1. **Host Connects:** The host initiates the connection by opening the designated USB endpoint for the selected iOS device.
2. **Device Sends Ping:**  The device sends a `PING` packet as a readiness signal.
3. **Host Replies with Ping:** The host responds with its own `PING` packet, acknowledging the device's readiness.
4. **Audio Clock Synchronization:**
   - The device sends `SYNC_CWPA` containing its audio clock reference.
   - The host creates a local audio clock and replies with `RPLY` containing its local clock reference.
5. **Video Configuration:**
   - If audio-only mode is not requested, the host sends `ASYN_HPD1` containing video device information.
6. **Audio Configuration:**
   - The host sends `ASYN_HPA1` containing audio device information and the device's audio clock reference.
7. **Audio Format Negotiation:**
   - The device sends `SYNC_AFMT` with its audio format details (AudioStreamBasicDescription).
   - The host replies with `RPLY` containing an error code of 0 to indicate acceptance.
8. **Video Clock Synchronization:**
   - The device sends `SYNC_CVRP` containing its video clock reference and the video format description.
   - The host creates a local video clock and replies with `RPLY` containing its clock reference.
9. **Initial Video Data Request:**
   - The host sends `ASYN_NEED` with the device's video clock reference to initiate the video stream.
10. **Device Sends Set Properties:** The device sends two `ASYN_SPRP` packets setting video stream properties.
11. **Clock Creation and Time Synchronization:**
    - The device sends `SYNC_CLOK` requesting the host to create a new clock.
    - The host creates the clock and replies with `RPLY` containing the clock reference.
    - The device sends two `SYNC_TIME` requests for the new clock.
    - The host replies to each `SYNC_TIME` with `RPLY` containing the current `CMTime` of the new clock. 

**7.2 Data Streaming Phase:**

1. **Audio Streaming:**
   - The device continuously sends `ASYN_EAT!` packets containing audio data and its audio clock reference.
   - The host processes the audio data and handles clock synchronization using periodic `SYNC_SKEW` packets.
2. **Video Streaming:**
   - The device continuously sends `ASYN_FEED` packets containing video data and the host's video clock reference. 
   - The host processes the video data.
3. **Periodic Video Data Request:**
   - The host periodically sends `ASYN_NEED` packets with the device's video clock reference to request more video frames, ensuring smooth playback.
4. **Ongoing Clock Synchronization:**
   - The device and host exchange `SYNC_SKEW` and `SYNC_TIME` packets periodically to maintain accurate clock synchronization for both audio and video.

**7.3 Shutdown Phase:**

1. **Host Signals Stop:**
   - The host sends `ASYN_HPA0` with the device's audio clock reference to stop audio streaming.
   - The host sends `ASYN_HPD0` to stop video streaming.
2. **Device Acknowledges Stop:**
   - The device sends `SYNC_STOP` to confirm stopping the video clock.
   - The host replies with `RPLY` containing zeros.
3. **Device Releases Clocks:**
   - The device sends `ASYN_RELS` for the local video clock reference.
   - The device sends `ASYN_RELS` for the other local clock created during `SYNC_CLOK`.
4. **Host Disconnects:**
   - The host releases the USB endpoint and closes the connection. 
   - The host may optionally send a control request to disable the QT-Config on the device, returning it to the default USBMux configuration.

**7.4 State Transitions:**

The session transitions through the following states:

* **Device Idle:**  Initial state, no active session.
* **Waiting for Ping:** Host connects, waiting for the initial `PING` from the device.
* **Streaming:** Active session, data and synchronization messages are exchanged.
* **Stopping:** Host initiated shutdown, waiting for device to acknowledge and release resources. 

Each state transition is triggered by specific messages exchanged between the host and the device.

This session lifecycle description outlines the basic flow of communication and state transitions. 
The actual implementation may include additional messages and states for handling specific scenarios and error conditions. 
