# Changelog

## Version History

### [1.0.0] - 2026-09-01

#### ✨ Features
- **Core Education Platform**
  - Story-based moral education for grades 3-4 (ages 8-10)
  - Interactive choice-based learning system with multiple story paths
  - Real-time feedback on ethical decisions
  - Narration support (text-to-speech) for accessibility

- **Child Learning Experience**
  - Intuitive UI optimized for young learners
  - Badge system for achievement motivation
  - Learning progress visualization
  - Offline support for previously downloaded content

- **Parental Oversight**
  - Monthly growth reports with radar charts showing ethical development
  - Learning analytics dashboard
  - Real-time notifications on significant milestones
  - Data-driven insights on child's decision-making patterns

- **Security & Privacy**
  - COPPA (Children's Online Privacy Protection Act) compliance
  - Firebase Firestore security rules for data protection
  - Parental consent system for data processing
  - End-to-end encryption for sensitive data
  - No storage of birthdates (age determination via school grade only)

- **Technical Foundation**
  - Cross-platform support (iOS & Android)
  - Flutter + Riverpod architecture
  - Firebase backend integration
  - FastAPI backend for analytics
  - SQLite local caching

#### 🔧 Infrastructure
- **CI/CD Pipeline**
  - Automated testing on every push
  - Release builds with Android signing
  - Artifact upload to GitHub
  - Security scanning (Flutter lints, secret detection, dependency checks)

- **Build & Signing**
  - Android release keystore generation
  - Gradle configuration for release signing
  - GitHub Secrets integration
  - iOS App Store signing setup

- **Deployment**
  - GitHub Actions workflows for Android releases
  - Artifact versioning and tracking
  - Automated release notes generation

#### 🔒 Security Enhancements
- **Code Quality**
  - Flutter static analysis with flutter_lints
  - Backend code analysis with Bandit
  - Dependency vulnerability scanning (Safety)
  - Git secret detection (Gitleaks)

- **Data Protection**
  - Firebase Firestore security rules
  - Firebase Storage security rules
  - Parental consent enforcement
  - Audit logging for sensitive operations

#### 📱 Compatibility
- **Android**: API Level 21+ (Android 5.0)
- **iOS**: iOS 12.0+
- **Flutter**: 3.24.0 (stable)
- **Dart**: 3.3.0+

#### 🎯 Target Audience
- **Primary Users**: Children aged 8-10 (grades 3-4)
- **Secondary Users**: Parents (for monitoring and consent)
- **Languages**: Japanese (ja), English (en)

#### 📊 Performance
- App startup: < 3 seconds
- Story loading: < 1 second
- Report generation: < 5 seconds
- Offline mode: Full functionality

#### ⚙️ System Requirements
- **Development**:
  - Flutter SDK 3.24.0+
  - Dart 3.3.0+
  - Android Studio / Xcode
  - Firebase CLI
  - Python 3.11+ (backend)

- **Production**:
  - Firebase Cloud (Firestore, Storage, Auth)
  - FastAPI server (analytics)
  - PostgreSQL database (analytics)
  - Cloud Storage (media files)

---

## Upgrade Guide

### From Initial Development (v0.1.0) → v1.0.0

#### Breaking Changes
None - First production release

#### Migration Steps
1. Update Flutter to 3.24.0+
2. Run `flutter pub get`
3. Execute `flutter pub run build_runner build`
4. Configure Firebase production project
5. Set up GitHub Secrets for release builds

#### New Environment Variables
- `.env.production` (update with production Firebase credentials)
- `KEYSTORE_PASSWORD` (GitHub Secret)
- `KEYSTORE_ALIAS` (GitHub Secret)
- `KEYSTORE_KEY_PASSWORD` (GitHub Secret)

---

## Known Issues & Limitations

### v1.0.0
- **Audio Narration**: Some text-to-speech engines may have pronunciation issues with uncommon Kanji
- **Offline Sync**: Manual refresh required after returning online (auto-sync planned for v1.1)
- **Parental Controls**: Email-based verification only (SMS planned for v1.1)

---

## Roadmap

### v1.1.0 (Planned)
- [ ] Auto-sync when returning online
- [ ] SMS-based parental verification
- [ ] Customizable learning paths based on preferences
- [ ] Parent-to-child messaging system
- [ ] Enhanced report visualizations

### v1.2.0 (Planned)
- [ ] Multi-language support (English, Chinese)
- [ ] Teacher dashboard for classroom integration
- [ ] Gamified learning with leaderboards (privacy-safe)
- [ ] Expanded story library (50+ new stories)
- [ ] Video-based lessons

### v2.0.0 (Planned)
- [ ] Web portal for parents
- [ ] AI-powered personalized recommendations
- [ ] Integration with school systems
- [ ] Advanced analytics with ML insights
- [ ] Wearable device support

---

## Support & Feedback

- **Report Issues**: https://github.com/zkaz83/shinshin/issues
- **Feature Requests**: https://github.com/zkaz83/shinshin/discussions
- **Security Concerns**: Contact security@shougaku-kore.jp

---

## License

This project is proprietary software developed by Petitworks Inc.

---

## Acknowledgments

- Flutter team for the amazing cross-platform framework
- Firebase team for robust backend infrastructure
- Community contributors and beta testers

---

**Last Updated**: 2026-09-01  
**Maintained By**: Petitworks Inc.  
**Official Website**: https://shougaku-kore.jp
