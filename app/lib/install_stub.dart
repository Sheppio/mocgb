// Phone builds: installed from the app stores, so there's nothing to offer.
import 'package:flutter/foundation.dart';

import 'install.dart';

ValueNotifier<InstallOffer> watchInstallOffer() => ValueNotifier(InstallOffer.none);

void showInstallPrompt() {}
