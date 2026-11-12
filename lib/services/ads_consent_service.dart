import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Requests up-to-date UMP consent before any ads are loaded.
///
/// The SDK decides which regions need a consent message. Ads remain disabled
/// until canRequestAds() confirms an eligible status. This also works when a
/// previously stored consent decision may be reused after a network error.
class AdsConsentService {
  AdsConsentService._();
  static final instance = AdsConsentService._();

  final ValueNotifier<bool> canLoadAds = ValueNotifier<bool>(false);
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);
  bool _started = false;
  bool _adsInitialized = false;

  void start() {
    if (_started) return;
    _started = true;
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await _refreshEligibility();
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            if (error != null) {
              debugPrint('Consent form failed: ${error.message}');
            }
            await _refreshEligibility();
          });
        } catch (error) {
          debugPrint('Could not load consent form: $error');
          await _refreshEligibility();
        }
      },
      (error) async {
        debugPrint('Consent information update failed: ${error.message}');
        await _refreshEligibility();
      },
    );
  }

  Future<void> _refreshEligibility() async {
    try {
      privacyOptionsRequired.value =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
      final eligible = await ConsentInformation.instance.canRequestAds();
      if (!eligible) {
        canLoadAds.value = false;
        return;
      }
      if (!_adsInitialized) {
        _adsInitialized = true;
        try {
          await MobileAds.instance.initialize();
        } catch (error) {
          _adsInitialized = false;
          debugPrint('Mobile Ads initialization failed: $error');
          return;
        }
      }
      canLoadAds.value = true;
    } catch (error) {
      debugPrint('Could not verify ads consent: $error');
    }
  }

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) async {
      if (error != null) {
        debugPrint('Privacy options failed: ${error.message}');
      }
      await _refreshEligibility();
    });
  }
}
