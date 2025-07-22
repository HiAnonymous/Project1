# InsightQuill - College Feedback System

A comprehensive Flutter application for college feedback management featuring quiz creation, biometric-based attendance tracking, and faculty evaluation.

## 🚀 Features

### Faculty Interface
- **Dashboard Overview**: View courses, student enrollment, and upcoming classes
- **Quiz Creation**: Create quizzes with 5 questions manually or via AI integration (Gemini API ready)
- **Automated Scheduling**: Quizzes auto-start 35 minutes after lecture begins
- **Quiz Management**: Cancel quizzes within the 35-minute window
- **Analytics Dashboard**: View detailed performance analytics and student submissions
- **Biometric Integration**: Attendance tracking simulation

### Student Interface
- **Student Dashboard**: View enrolled courses and available quizzes
- **Quiz Taking**: Secure quiz environment with anti-cheat features
- **Feedback System**: 5-star rating system with comments for faculty evaluation
- **Performance Tracking**: View personal quiz results and scores
- **Timetable Integration**: Access quizzes based on class schedule

### Anti-Cheat Features
- **App Lock Simulation**: Prevents switching between apps during quiz
- **Background Detection**: Warns when students leave the app
- **Time-based Validation**: Automatic submission when time expires
- **Fullscreen Mode**: Immersive quiz-taking experience

## 📱 App Screenshots & Demo Accounts

### Faculty Demo Accounts
- `sarah.johnson@college.edu` - Computer Science Department
- `michael.chen@college.edu` - Mathematics Department  
- `emily.davis@college.edu` - Physics Department

### Student Demo Accounts
- `CS2021001` - Alex Rodriguez (Computer Science)
- `CS2021002` - Emma Thompson (Computer Science)
- `CS2021003` - James Wilson (Computer Science)
- `MATH2021001` - Sophia Martinez (Mathematics)
- `PHY2021001` - Liam Brown (Physics)

## 🏗️ Technical Architecture

### Core Technologies
- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **Shared Preferences**: Local data persistence
- **Material 3**: Modern design system

### App Structure
```
lib/
├── models/          # Data models (User, Quiz, Course, Feedback)
├── services/        # Business logic (DataService, AuthService)
├── providers/       # State management (AppProvider)
├── screens/         # UI screens
└── theme.dart       # App theming
```

### Key Models
- **User**: Faculty and student profiles with role-based access
- **Quiz**: Question management with support for text and images
- **Course**: Course enrollment and timetable integration
- **Feedback**: Rating system for faculty evaluation
- **BiometricData**: Simulated attendance tracking

## 🎯 User Flows

### Faculty Workflow
1. Login with faculty email
2. View dashboard with course overview
3. Create quiz with 5 questions
4. Quiz automatically activates after 35 minutes
5. Monitor real-time submissions
6. View detailed analytics and performance metrics

### Student Workflow
1. Login with registration number
2. View available quizzes based on attendance
3. Take secure quiz with 7-minute time limit
4. Submit feedback rating for faculty
5. View personal performance results

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 📊 Data Management

### Dummy Data Included
- **3 Faculty Members** across different departments
- **5 Students** with varied course enrollments
- **Sample Quizzes** with realistic questions
- **Timetable Data** for class scheduling
- **Biometric Simulation** for attendance tracking

### Local Storage
- User sessions via SharedPreferences
- Quiz submissions and feedback stored locally
- Offline capability for uninterrupted usage

## 🎨 Design Philosophy

### Modern UI/UX
- **Material 3** design system
- **Gradient backgrounds** and smooth animations
- **Card-based layouts** for content organization
- **Responsive design** for various screen sizes

### Accessibility
- High contrast color schemes
- Clear typography hierarchy
- Intuitive navigation patterns
- Screen reader compatibility

## 🚦 Anti-Cheat Implementation

### Security Measures
1. **Kiosk Mode**: Locks device to quiz app during examination
2. **App Lifecycle Monitoring**: Detects when students leave the app
3. **Time Constraints**: Automatic submission on time expiry
4. **Warning System**: Visual alerts for suspicious behavior

## 📈 Analytics & Reporting

### Faculty Analytics
- **Performance Overview**: Class-wide statistics and averages
- **Question Analysis**: Individual question difficulty assessment
- **Student Rankings**: Performance-based leaderboards
- **Submission Timeline**: Real-time quiz completion tracking

### Feedback Analytics
- **Rating Distribution**: Visual breakdown of faculty ratings
- **Comment Analysis**: Recent feedback compilation
- **Trend Monitoring**: Performance changes over time

## 🔮 Future Enhancements

### Planned Features
- **AI Integration**: Google Gemini API for automatic question generation
- **Real Biometric**: Actual fingerprint/face recognition integration
- **Cloud Sync**: Firebase/Supabase backend integration
- **Advanced Analytics**: ML-powered performance insights
- **Offline Mode**: Enhanced offline functionality

### Technical Improvements
- **Push Notifications**: Quiz reminders and announcements
- **File Upload**: Support for multimedia questions
- **Export Features**: PDF reports and data export
- **Multi-language**: Internationalization support

## 📞 Support & Contribution

This is a demo application showcasing comprehensive Flutter development practices including:
- **State management** with Provider pattern
- **Modern UI design** with Material 3
- **Complex navigation** and routing
- **Local data persistence**
- **Real-world app architecture**

The codebase demonstrates professional Flutter development standards suitable for educational institutions and assessment platforms.

---

**Built with ❤️ using Flutter** | **Educational Technology Solution**