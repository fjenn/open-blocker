# Open Blocker Format Reference Implementation

This directory contains the reference Kotlin implementation of the Open Blocker tag format encoder and decoder.

## Building

```bash
./gradlew build
```

## Running Tests

```bash
./gradlew test
```

The tests cover both test vectors from the specification and additional edge cases.

## Using the Library

```kotlin
import app.openblocker.format.OpenBlockerFormat

// Generate a new tag
val tagId = OpenBlockerFormat.generateTagId()
val data = OpenBlockerFormat.TagData(
    tagId = tagId,
    androidPackage = "app.openblocker.android"
)

// Encode to NDEF message
val ndefMessage = OpenBlockerFormat.encode(data)

// Wrap for writing to tag
val tlvData = OpenBlockerFormat.wrapInTLV(ndefMessage)

// Write tlvData to NFC tag...

// Reading from tag
val readTlvData = // ... read from NFC tag
val readNdefMessage = OpenBlockerFormat.unwrapFromTLV(readTlvData)
val readData = OpenBlockerFormat.decode(readNdefMessage)

println("Tag ID: ${OpenBlockerFormat.tagIdToUuid(readData.tagId)}")
```

## Integration with Android App

The Android app includes this format implementation directly. Copy `OpenBlockerFormat.kt` to your Android project and use it with the Android NFC APIs.
