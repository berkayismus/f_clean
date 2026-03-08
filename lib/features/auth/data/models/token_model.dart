import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_model.freezed.dart';
part 'token_model.g.dart';

@freezed
abstract class TokenModel with _$TokenModel {
  const factory TokenModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _TokenModel;

  factory TokenModel.fromJson(Map<String, dynamic> json) =>
      _$TokenModelFromJson(json);
}
