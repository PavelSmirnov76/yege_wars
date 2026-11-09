import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';

class FakeProgressRepository implements ProgressRepository {
  Result<ProgressSummary> result = const Ok(
    ProgressSummary(byNumber: [], attempts: []),
  );
  final calls = <String>[];
  final gates = <String, Completer<Result<ProgressSummary>>>{};
  @override
  FutureResult<ProgressSummary> getProgress(String userId) {
    calls.add(userId);
    return gates[userId]?.future ?? Future.value(result);
  }
}
