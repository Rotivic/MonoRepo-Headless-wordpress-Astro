import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tcg_platform_mobile/core/network/constants.dart';
import 'package:tcg_platform_mobile/features/authentication/data/dtos/login_response_dto.dart';
import 'package:tcg_platform_mobile/features/authentication/data/dtos/response_message_dto.dart';
import 'package:tcg_platform_mobile/features/authentication/data/dtos/user_response_dto.dart';
import 'package:tcg_platform_mobile/features/profile/data/dtos/dropdown_dto.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio) = _ApiClient;

  @POST(NetworkConstants.callLogin)
  Future<LoginResponseDto> login(
    @Body() Map<String, dynamic> body,
  );

  @POST(NetworkConstants.callTwoFactorLogin)
  Future<LoginResponseDto> twoFactorLogin(
    @Body() Map<String, dynamic> body,
  );

  @GET(NetworkConstants.callCurrentUser)
  Future<UserResponseDto> getCurrentUser(
    @Header('Authorization') String authorization,
  );

  @POST(NetworkConstants.callRegister)
  Future<void> register(
    @Body() Map<String, dynamic> body,
  );

  @POST(NetworkConstants.callSendVerification)
  Future<void> sendVerification(
    @Header('Authorization') String authorization,
  );

  @POST(NetworkConstants.callVerifyEmailCode)
  Future<void> verifyEmailCode(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @POST(NetworkConstants.callForgotPassword)
  Future<void> forgotPassword(
    @Body() Map<String, dynamic> body,
  );

  @PUT(NetworkConstants.callProfileUpdate)
  Future<ResponseMessageDto> updateProfileInformation(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @POST(NetworkConstants.callProfileAvatar)
  @MultiPart()
  Future<ResponseMessageDto> updateProfileAvatar(
    @Header('Authorization') String authorization,
    @Part(name: 'avatar') MultipartFile avatar,
  );

  @PUT(NetworkConstants.callProfilePassword)
  Future<ResponseMessageDto> updateProfilePassword(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @POST(NetworkConstants.callLogout)
  Future<void> logout(
    @Header('Authorization') String authorization,
  );

  /*@POST(NetworkConstants.callUpdateUserImage)
  @MultiPart()
  Future<UpdateUserImageResponseDto> updateUserImage({
    @Part(name: 'imagen') required File image,
    @Part(name: 'data') required String data,
  });*/

  @GET(NetworkConstants.callGroupDropdown)
  Future<DropdownResponseDto> getGroupDropdown();

  @POST(NetworkConstants.callUserDropdown)
  @FormUrlEncoded()
  Future<DropdownResponseDto> getUserDropdown(
    @Field('group_slug') String groupSlug,
    @Field('search') String? search,
    @Field('user_id') int? userId,
  );

  /*@POST(NetworkConstants.callUpdateUser)
  @FormUrlEncoded()
  Future<UpdateUserImageResponseDto> updateUser(
      @Field('data') String data,
      );

  @POST(NetworkConstants.callReset)
  @FormUrlEncoded()
  Future<UpdateUserImageResponseDto> resetPassword(
      @Field('user_id') int userId,
      @Field('old_password') String oldPassword,
      @Field('new_password') String newPassword,
      );*/
}
