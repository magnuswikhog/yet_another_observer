## [2.0.0] May 27, 2022

- Added missing `hasChanged` parameter and fixed default values for observer methods in 
YAObserverManager and YAObserverStatefulMixin.
- Removed the `super.build()` requirement from YAObserverStatefulMixin and replaced it with
an `updateObservers()` that can be called from anywhere to update all observers. This makes it
possible to update observers for example from within a `ScopedModel` builder instead of only
from outside it (which would defeat its purpose).
- Improved documentation about observing non-scalar values.


## [1.0.0] May 26, 2022

Replaced event.previous with event.history.
Updated test and documentation.
Formatted the code.

## [0.0.1] May 26, 2022

Initial release.