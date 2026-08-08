import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  // Static session state cache
  static String? _currentToken;
  static UserModel? _currentUser;

  final ApiClient _apiClient = ApiClient();

  /// Active session getters
  static String? get currentToken => _currentToken;
  static UserModel? get currentUser => _currentUser;

   /// Process authentication data
    void _processAuthData(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['token'] != null) {
        _currentToken = data['token'];
      }
      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      }
    }
  }

  /// Authenticate user via Google OAuth details
  Future<Map<String, dynamic>> googleAuthenticate({
    required String email,
    required String name,
  }) async {
    final responseData = await _apiClient.post('/auth/google', body: {
      'email': email,
      'name': name,
    });

    final fullResponse = {'data': responseData};
    _processAuthData(responseData);
    return fullResponse;
  }

  /// Register standard user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? password,
  }) async {
    final responseData = await _apiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
    });

    final fullResponse = {'data': responseData};
    _processAuthData(responseData);
    return fullResponse;
  }

  /// Login standard user
  Future<Map<String, dynamic>> login({
    required String email,
    String? password,
  }) async {
    final responseData = await _apiClient.post('/auth/login', body: {
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
    });

    final fullResponse = {'data': responseData};
    _processAuthData(responseData);
    return fullResponse;
  }

  /// Fetch authenticated user profile from backend GET /auth/me
  Future<UserModel> fetchCurrentUser() async {
    final data = await _apiClient.get('/auth/me');
    
    if (data is Map<String, dynamic> && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      final existingRatings = _currentUser?.sportRatings;
      final finalUser = (existingRatings != null && existingRatings.length > 1 && user.sportRatings.length <= 1)
          ? user.copyWith(sportRatings: Map<String, int>.from(existingRatings))
          : user;

      _currentUser = finalUser;
      return finalUser;
    }
    throw Exception('Failed to fetch user session');
  }

  /// Complete first-time user onboarding
  Future<UserModel> completeOnboarding({
    String? name,
    required String primarySport,
    required int rating,
    String? avatarUrl,
  }) async {
    final sportKey = primarySport.toLowerCase();
    final data = await _apiClient.patch('/auth/onboard', body: {
      if (name != null && name.isNotEmpty) 'name': name,
      'primary_sport': sportKey,
      'rating': rating,
      'sport_ratings': {sportKey: rating},
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
    });

    if (data is Map<String, dynamic> && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      final finalUser = user.copyWith(sportRatings: {sportKey: rating});
      _currentUser = finalUser;
      return finalUser;
    }
    throw Exception('Failed to complete onboarding');
  }

  /// Update user profile details
  Future<UserModel> updateProfile({
    String? name,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? phoneNumber,
    String? location,
    String? bio,
  }) async {
    final data = await _apiClient.patch('/auth/onboard', body: {
      if (name != null && name.isNotEmpty) 'name': name,
      'avatar_url': avatarUrl,
      'cover_photo_url': coverPhotoUrl,
      'phone_number': phoneNumber,
      'location': location,
      'bio': bio,
    });

    if (data is Map<String, dynamic> && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      final existingRatings = _currentUser?.sportRatings;
      final finalUser = (existingRatings != null && existingRatings.length > 1 && user.sportRatings.length <= 1)
          ? user.copyWith(sportRatings: Map<String, int>.from(existingRatings))
          : user;
      _currentUser = finalUser;
      return finalUser;
    }
    throw Exception('Failed to update profile');
  }

  /// Update user sport preferences and per-sport ELO ratings
  Future<UserModel> updateSportPreferences(Map<String, int> sportRatings) async {
    final data = await _apiClient.patch('/auth/onboard', body: {
      'sport_ratings': sportRatings,
    });

    if (data is Map<String, dynamic> && data['user'] != null) {
      final backendUser = UserModel.fromJson(data['user']);
      final updatedUser = backendUser.copyWith(
        sportRatings: Map<String, int>.from(sportRatings),
      );
      _currentUser = updatedUser;
      return updatedUser;
    }
    throw Exception('Failed to update sport preferences');
  }

  /// Update or set user password
  Future<UserModel> updatePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final data = await _apiClient.put('/auth/password', body: {
      if (currentPassword != null && currentPassword.isNotEmpty)
        'current_password': currentPassword,
      'new_password': newPassword,
    });

    if (data is Map<String, dynamic> && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      _currentUser = user;
      return user;
    }
    throw Exception('Failed to update password');
  }

  /// Upload user avatar image bytes via Cloudflare R2 presigned URL
  Future<String?> uploadAvatarImage(
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final presignedData = await _apiClient.post('/upload/presigned-url', body: {
      'contentType': mimeType,
    });

    final String uploadUrl = presignedData['uploadUrl'];
    final String avatarUrl = presignedData['avatarUrl'];

    // Direct binary PUT to Cloudflare R2 presigned URL
    await _apiClient.put(uploadUrl, body: imageBytes, headers: {'Content-Type': mimeType});
    return avatarUrl;
  }

  /// Permanently delete authenticated user account and clear session
  Future<void> deleteAccount() async {
    await _apiClient.delete('/auth/me');
    await logout();
  }

  /// Clear active user session & sign out Google OAuth
  static Future<void> logout() async {
    SocketService().disconnect();
    _currentToken = null;
    _currentUser = null;
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }
}
