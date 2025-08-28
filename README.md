# VibeAlarm - Android AlarmManager Integration

A Flutter alarm app with full Android AlarmManager integration for reliable, system-level alarm functionality.

## 🚀 Features

### **Core Alarm Functionality**
- ✅ **Real Android Alarms** - Uses Android AlarmManager for system-level scheduling
- ✅ **Background Processing** - Alarms work even when app is closed
- ✅ **Device Wake-up** - Wakes device from sleep/deep sleep
- ✅ **Audio Playback** - Plays custom or default alarm sounds
- ✅ **Vibration** - Device vibration with custom patterns
- ✅ **Recurring Alarms** - Daily, weekly, weekdays, weekends, custom days

### **Advanced Features**
- ✅ **AI-Generated Audio** - Google Cloud TTS integration
- ✅ **Audio Library** - Pre-installed and custom audio files
- ✅ **Burst Alarms** - Multiple alarms in sequence
- ✅ **Snooze Functionality** - Multiple snooze intervals
- ✅ **Alarm Categories** - Work, personal, mood-based alarms
- ✅ **Database Persistence** - SQLite storage with automatic upgrades

### **System Integration**
- ✅ **Boot Persistence** - Alarms survive device reboots
- ✅ **Battery Optimization Bypass** - Works with aggressive battery saving
- ✅ **Audio Focus Management** - Handles interruptions gracefully
- ✅ **Wake Lock Management** - Prevents device sleep during alarms
- ✅ **Notification Integration** - System notifications with actions

## 🛠️ Technical Implementation

### **Android AlarmManager Integration**
- **Native Scheduling**: Uses `android_alarm_manager_plus` for precise timing
- **Background Processing**: `workmanager` for reliable background tasks
- **Wake Locks**: `wakelock_plus` to prevent device sleep
- **Audio Session**: `audio_session` for proper audio focus management
- **Local Notifications**: `flutter_local_notifications` for system integration

### **Database Schema**
- **Version 5**: Latest schema with scheduling fields
- **Automatic Upgrades**: Handles database migrations seamlessly
- **Alarm History**: Tracks triggered alarms and snooze counts
- **Audio Metadata**: Stores TTS parameters and file information

### **Audio System**
- **Custom Audio**: Support for MP3, WAV, and other formats
- **AI Generation**: Google Cloud TTS with mood-based voices
- **Audio Library**: Organized collection management
- **Playback Controls**: Play, pause, stop, volume, progress

## 📱 Usage

### **Creating Alarms**
1. **Basic Alarm**: Set time, frequency, and audio
2. **AI Audio**: Generate custom audio from text with mood selection
3. **Custom Audio**: Use pre-installed or uploaded audio files
4. **Burst Alarm**: Create multiple alarms in sequence

### **Managing Alarms**
- **Toggle**: Activate/deactivate alarms
- **Edit**: Modify time, frequency, audio, and settings
- **Delete**: Remove alarms with swipe gesture
- **Snooze**: Extend alarm time when triggered

### **Testing**
- **Test Button**: Use the test alarm button in the home screen
- **1-Minute Test**: Creates a test alarm for immediate testing
- **Debug Info**: Check console logs for detailed information

## 🔧 Setup & Configuration

### **Environment Variables**
Create a `.env` file in the project root:
```env
GOOGLE_TTS_API_KEY=your_api_key_here
GOOGLE_TTS_BASE_URL=https://texttospeech.googleapis.com/v1/text:synthesize
```

### **Android Permissions**
The app automatically requests these permissions:
- `WAKE_LOCK` - Prevents device sleep
- `SCHEDULE_EXACT_ALARM` - Precise alarm scheduling
- `USE_EXACT_ALARM` - System alarm access
- `FOREGROUND_SERVICE` - Background processing
- `VIBRATE` - Device vibration
- `RECEIVE_BOOT_COMPLETED` - Boot persistence

### **Dependencies**
All required packages are included in `pubspec.yaml`:
```yaml
android_alarm_manager_plus: ^2.1.4
workmanager: ^0.5.2
wakelock_plus: ^1.1.4
audio_session: ^0.1.18
flutter_local_notifications: ^16.3.2
device_info_plus: ^9.1.2
```

## 🚨 Troubleshooting

### **Common Issues**
1. **Alarms Not Triggering**: Check battery optimization settings
2. **Audio Not Playing**: Verify audio file paths and permissions
3. **App Crashing**: Ensure all dependencies are properly installed
4. **Background Issues**: Grant necessary permissions in device settings

### **Debug Information**
- Check console logs for detailed error messages
- Use the test alarm button to verify functionality
- Monitor database viewer for alarm status
- Check notification settings and permissions

### **Performance Tips**
- Limit concurrent alarms to avoid system overload
- Use appropriate audio file sizes for faster loading
- Regular app usage helps maintain background permissions
- Monitor battery usage and adjust settings accordingly

## 🔮 Future Enhancements

### **Planned Features**
- **Smart Alarms**: Motion detection and gradual volume increase
- **Weather Integration**: Weather-based alarm adjustments
- **Alarm Statistics**: Usage analytics and insights
- **Cloud Sync**: Cross-device alarm synchronization
- **Voice Commands**: Voice-controlled alarm management

### **Platform Expansion**
- **iOS Support**: Local notifications and audio session management
- **Web Support**: Progressive web app functionality
- **Desktop Support**: Cross-platform alarm management

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

---

**Note**: This app requires Android 6.0 (API level 23) or higher for full functionality. Some features may be limited on older devices.
