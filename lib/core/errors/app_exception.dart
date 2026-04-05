/// 앱 전체에서 사용하는 표준 예외 계층
///
/// 사용 원칙:
/// - 네트워크/API 호출 실패 → [NetworkException]
/// - 에어코리아 API 오류 응답 (resultCode ≠ '00') → [ApiException]
/// - JSON 파싱 실패 → [ParseException]
///
/// catch 블록에서 `Exception('...')` 대신 이 타입들을 사용한다.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃
class NetworkException extends AppException {
  const NetworkException([
    super.message = '네트워크에 연결할 수 없어요.\n잠시 후 다시 시도해 주세요.',
  ]);
}

/// 에어코리아 API가 오류 응답을 반환한 경우 (resultCode ≠ '00')
class ApiException extends AppException {
  final String? code;
  const ApiException(super.message, {this.code});
}

/// 응답 데이터 파싱 실패
class ParseException extends AppException {
  const ParseException([
    super.message = '데이터를 읽는 중 오류가 발생했어요.',
  ]);
}
