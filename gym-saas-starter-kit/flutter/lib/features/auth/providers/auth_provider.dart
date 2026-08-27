import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

// ─── Global Providers ───────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(supabaseClientProvider));
});

final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  return _buildAuthStateStream(service);
});

Stream<AuthState> _buildAuthStateStream(AuthService service) async* {
  yield const AuthState(isLoading: true);

  await for (final _ in service.authStateChanges) {
    final member = await service.getCurrentMember();
    if (member != null) {
      yield AuthState(member: member, isLoading: false);
    } else {
      yield const AuthState(isLoading: false);
    }
  }
}

final selectedGymProvider = StateProvider<Gym?>((ref) => null);

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(selectedGymProvider.notifier),
  );
});

// ─── AuthNotifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StateController<Gym?> _gymController;

  AuthNotifier(this._authService, this._gymController)
      : super(const AuthState());

  void selectGym(Gym gym) {
    _gymController.state = gym;
  }

  void clearGym() {
    _gymController.state = null;
  }

  Future<void> requestOtp({String? email, String? phone}) async {
    final gym = _gymController.state;
    if (gym == null) {
      state = state.copyWith(error: 'Please select a gym first');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.requestOtp(
        email: email,
        phone: phone,
        gymId: gym.id,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error');
    }
  }

  Future<bool> verifyOtp({
    String? email,
    String? phone,
    required String token,
  }) async {
    final gym = _gymController.state;
    if (gym == null) {
      state = state.copyWith(error: 'Gym selection lost');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyOtp(
        email: email,
        phone: phone,
        token: token,
        gymId: gym.id,
      );

      final member = await _authService.getCurrentMember();
      state = state.copyWith(isLoading: false, member: member);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    _gymController.state = null;
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
