import 'package:DRUN/core/errors/failures.dart';
import 'package:DRUN/core/presentation/util/input_validator.dart';
import 'package:DRUN/features/authentication/domain/entities/authentication_sms_status.dart';
import 'package:DRUN/features/authentication/domain/entities/user_credentials.dart';
import 'package:DRUN/features/authentication/domain/usecases/get_logged_in_user.dart';
import 'package:DRUN/features/authentication/domain/usecases/send_authentication_sms.dart';
import 'package:DRUN/features/authentication/domain/usecases/verify_authentication_sms.dart';
import 'package:DRUN/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockGetLoggedInUser extends Mock implements GetLoggedInUser {}

class MockSendAuthenticationSms extends Mock implements SendAuthenticationSms {}

class MockVerifyAuthenticationSms extends Mock
    implements VerifyAuthenticationSms {}

class MockInputValidator extends Mock implements InputValidator {}

void main() {
  AuthenticationBloc bloc;
  MockGetLoggedInUser mockGetLoggedInUser;
  MockSendAuthenticationSms mockSendAuthenticationSms;
  MockVerifyAuthenticationSms mockVerifyAuthenticationSms;
  MockInputValidator mockInputValidator;

  setUp(() {
    mockGetLoggedInUser = MockGetLoggedInUser();
    mockSendAuthenticationSms = MockSendAuthenticationSms();
    mockVerifyAuthenticationSms = MockVerifyAuthenticationSms();
    mockInputValidator = MockInputValidator();
    bloc = AuthenticationBloc(
      getLoggedInUser: mockGetLoggedInUser,
      sendAuthenticationSms: mockSendAuthenticationSms,
      verifyAuthenticationSms: mockVerifyAuthenticationSms,
      inputValidator: mockInputValidator,
    );
  });

  test(
    'initialState should be AuthenticationInitial',
    () async {
      expect(bloc.initialState, AuthenticationInitialState());
    },
  );

  group('GetLoggedInUserEvent', () {
    final tUserCredentials = UserCredentials(
      userId: "4ade5874-c573-4c8f-b2b8-7db5fccd983b",
      userToken:
          "713ADC1F515B3E0BBDF964DBAE6257A5B8A617115816A1705EACF9C00394A5",
    );
  });

  group('SendAuthenticationSmsEvent', () {
    final tPhoneNumber = '+359735780085';
    final tAuthenticationSmsStatus = AuthenticationSmsStatus(
      phoneNumber: '+359735780085',
      succeeded: true,
    );

    test(
      'should call the InputValidator to validate phoneNumber',
      () async {
        // Arrange
        when(mockInputValidator.stringAsPhoneNumber(tPhoneNumber))
            .thenReturn(Right(tPhoneNumber));

        // Act
        bloc.add(SendAuthenticationSmsEvent(tPhoneNumber));
        await untilCalled(mockInputValidator.stringAsPhoneNumber(any));

        // Assert
        verify(mockInputValidator.stringAsPhoneNumber(tPhoneNumber));
      },
    );

    test(
      'should emit AuthenticationErrorState when the input is invalid',
      () async {
        // Arrange
        when(mockInputValidator.stringAsPhoneNumber(any)).thenReturn(
          Left(InvalidInputFailure()),
        );

        // Assert later
        final expected = [
          AuthenticationInitialState(),
          AuthenticationErrorState(message: InvalidInputFailure().message)
        ];
        expectLater(bloc, emitsInOrder(expected));

        // Act
        bloc.add(SendAuthenticationSmsEvent(tPhoneNumber));
      },
    );

    test(
      'should get data from the SendAuthenticationSms usecase',
      () async {
        // Arrange
        when(mockInputValidator.stringAsPhoneNumber(tPhoneNumber))
            .thenReturn(Right(tPhoneNumber));

        when(mockSendAuthenticationSms(any))
            .thenAnswer((_) async => Right(tAuthenticationSmsStatus));

        // Act
        bloc.add(SendAuthenticationSmsEvent(tPhoneNumber));
        await untilCalled(mockSendAuthenticationSms(any));

        // Assert
        verify(
          mockSendAuthenticationSms(SendParams(phoneNumber: tPhoneNumber)),
        );
      },
    );

    test(
      'should emit AuthenticationLoadingState and AuthenticationCodeInputState when data is gotten',
      () async {
        // Arrange
        when(mockInputValidator.stringAsPhoneNumber(tPhoneNumber))
            .thenReturn(Right(tPhoneNumber));

        when(mockSendAuthenticationSms(any))
            .thenAnswer((_) async => Right(tAuthenticationSmsStatus));

        // Assert later
        final expected = [
          AuthenticationInitialState(),
          AuthenticationLoadingState(),
          AuthenticationCodeInputState(
            authenticationSmsStatus: tAuthenticationSmsStatus,
          ),
        ];
        expectLater(bloc, emitsInOrder(expected));

        // Act
        bloc.add(SendAuthenticationSmsEvent(tPhoneNumber));
      },
    );

    test(
      'should emit AuthenticationLoadingState and AuthenticationErrorState when usecase fails',
      () async {
        // Arrange
        when(mockInputValidator.stringAsPhoneNumber(tPhoneNumber))
            .thenReturn(Right(tPhoneNumber));

        when(mockSendAuthenticationSms(any))
            .thenAnswer((_) async => Left(ServerFailure()));

        // Assert later
        final expected = [
          AuthenticationInitialState(),
          AuthenticationLoadingState(),
          AuthenticationErrorState(message: ServerFailure().message),
        ];
        expectLater(bloc, emitsInOrder(expected));

        // Act
        bloc.add(SendAuthenticationSmsEvent(tPhoneNumber));
      },
    );
  });

  group('VerifyAuthenticationSmsEvent', () {
    final tPhoneNumber = '+359735780085';
    final tCode = '888888';
    final tUserCredentials = UserCredentials(
      userId: "4ade5874-c573-4c8f-b2b8-7db5fccd983b",
      userToken:
          "713ADC1F515B3E0BBDF964DBAE6257A5B8A617115816A1705EACF9C00394A5",
    );
  });
}
